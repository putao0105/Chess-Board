import SwiftUI

// Tal vs Hecht, Varna Olympiad 1962 — position after 19. exf6!!
// Built only with SwiftUI stacks (VStack / HStack / ZStack),
// shapes (Rectangle, RoundedRectangle, Circle, Capsule, Ellipse)
// and modifiers (.fill, .frame, .overlay, .offset, .rotationEffect).
//
// FEN: r3k2r/pb3pp1/2p1qPnp/1pp5/Q1N4B/2PB1P2/P5PP/R4RK1 b kq - 0 19

struct ContentView: View {
    // Rank 8 at the top, rank 1 at the bottom. Uppercase = White, lowercase = Black, "." = empty.
    let board: [String] = [
        "r...k..r",   // 8
        "pb...pp.",   // 7
        "..p.qPnp",   // 6
        ".pp.....",   // 5
        "Q.N....B",   // 4
        "..PB.P..",   // 3
        "P.....PP",   // 2
        "R....RK."    // 1
    ]
    let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
    let squareSize: CGFloat = 44

    let lightSquare = Color(red: 0.94, green: 0.85, blue: 0.71)
    let darkSquare  = Color(red: 0.71, green: 0.53, blue: 0.39)
    let moveSquare  = Color(red: 0.85, green: 0.76, blue: 0.29)   // e5 → f6

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { col in
                        square(row: row, col: col)
                    }
                }
            }
        }
        .border(Color.black.opacity(0.6), width: 1)
        .padding()
    }

    // One square = a colored Rectangle with an optional piece layered on top
    func square(row: Int, col: Int) -> some View {
        let isLight = (row + col) % 2 == 0
        let name = files[col] + "\(8 - row)"
        let isMove = (name == "e5" || name == "f6")
        let symbol = Array(board[row])[col]

        return ZStack {
            Rectangle()
                .fill(isMove ? moveSquare : (isLight ? lightSquare : darkSquare))
            if symbol != "." {
                PieceView(symbol: symbol)
            }
        }
        .frame(width: squareSize, height: squareSize)
    }
}

// MARK: - Pieces drawn from shapes

// A tiny "pen" that draws on a 45 x 45 grid and scales to whatever frame the shape gets.
struct Pen {
    var path = Path()
    let rect: CGRect

    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + x / 45 * rect.width,
                y: rect.minY + y / 45 * rect.height)
    }
    mutating func m(_ x: CGFloat, _ y: CGFloat) { path.move(to: pt(x, y)) }
    mutating func l(_ x: CGFloat, _ y: CGFloat) { path.addLine(to: pt(x, y)) }
    mutating func c(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        path.addCurve(to: pt(x, y), control1: pt(x1, y1), control2: pt(x2, y2))
    }
    mutating func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) {
        let a = pt(cx - rx, cy - ry), b = pt(cx + rx, cy + ry)
        path.addEllipse(in: CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y))
    }
    mutating func z() { path.closeSubpath() }
}

// A custom Shape whose outline is drawn with a Pen
struct PieceShape: Shape {
    let draw: @Sendable (inout Pen) -> Void
    func path(in rect: CGRect) -> Path {
        var pen = Pen(rect: rect)
        draw(&pen)
        return pen.path
    }
}

struct PieceView: View {
    let symbol: Character

    var isWhite: Bool  { symbol.isUppercase }
    var fill: Color    { isWhite ? .white : Color(white: 0.12) }
    var outline: Color { .black }
    var detail: Color  { isWhite ? .black : Color(white: 0.85) }   // inner lines

    var body: some View {
        ZStack {
            switch symbol.lowercased() {
            case "p": pawn
            case "r": rook
            case "n": knight
            case "b": bishop
            case "q": queen
            default:  king
            }
        }
        .frame(width: 38, height: 38)
    }

    // Filled part with a black outline
    func solid(_ s: PieceShape) -> some View {
        s.fill(fill)
            .overlay(s.stroke(outline, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)))
    }
    // Inner detail lines (dark on white pieces, light on black pieces)
    func lines(_ s: PieceShape, color: Color? = nil, width: CGFloat = 1.2) -> some View {
        s.stroke(color ?? detail, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    // ♟ Pawn: head, collar and flared body in one silhouette
    var pawn: some View {
        solid(PieceShape { p in
            p.m(22.5, 9)
            p.c(20.29, 9, 18.5, 10.79, 18.5, 13)
            p.c(18.5, 13.89, 18.79, 14.71, 19.28, 15.38)
            p.c(17.33, 16.5, 16, 18.59, 16, 21)
            p.c(16, 23.03, 16.94, 24.84, 18.41, 26.03)
            p.c(15.41, 27.09, 11, 31.58, 11, 39.5)
            p.l(34, 39.5)
            p.c(34, 31.58, 29.59, 27.09, 26.59, 26.03)
            p.c(28.06, 24.84, 29, 23.03, 29, 21)
            p.c(29, 18.59, 27.67, 16.5, 25.72, 15.38)
            p.c(26.21, 14.71, 26.5, 13.89, 26.5, 13)
            p.c(26.5, 10.79, 24.71, 9, 22.5, 9)
            p.z()
        })
    }

    // ♜ Rook: base, plinth, shaft, shoulders and battlements
    var rook: some View {
        ZStack {
            solid(PieceShape { p in                       // base
                p.m(9, 39); p.l(36, 39); p.l(36, 36); p.l(9, 36); p.z()
            })
            solid(PieceShape { p in                       // plinth
                p.m(12, 36); p.l(12, 32); p.l(33, 32); p.l(33, 36); p.z()
            })
            solid(PieceShape { p in                       // lower collar
                p.m(14, 29.5); p.l(31, 29.5); p.l(32.5, 32); p.l(12.5, 32); p.z()
            })
            solid(PieceShape { p in                       // shaft
                p.m(14, 17); p.l(31, 17); p.l(31, 29.5); p.l(14, 29.5); p.z()
            })
            solid(PieceShape { p in                       // upper collar
                p.m(11, 14); p.l(34, 14); p.l(31, 17); p.l(14, 17); p.z()
            })
            solid(PieceShape { p in                       // battlements
                p.m(11, 14); p.l(11, 9); p.l(15, 9); p.l(15, 11); p.l(20, 11); p.l(20, 9)
                p.l(25, 9); p.l(25, 11); p.l(30, 11); p.l(30, 9); p.l(34, 9); p.l(34, 14); p.z()
            })
            lines(PieceShape { p in                       // visible seams on black rooks
                p.m(12, 35.5); p.l(33, 35.5)
                p.m(13, 31.5); p.l(32, 31.5)
                p.m(14, 29.5); p.l(31, 29.5)
                p.m(14, 16.5); p.l(31, 16.5)
                p.m(11, 14); p.l(34, 14)
            }, width: isWhite ? 1.2 : 0.9)
        }
    }

    // ♞ Knight: neck/chest, head with ear and muzzle, eye and nostril
    var knight: some View {
        ZStack {
            solid(PieceShape { p in                       // neck and chest
                p.m(22, 10)
                p.c(32.5, 11, 38.5, 18, 38, 39)
                p.l(15, 39)
                p.c(15, 30, 25, 32.5, 23, 18)
                p.z()
            })
            solid(PieceShape { p in                       // head
                p.m(24, 18)
                p.c(24.38, 20.91, 18.45, 25.37, 16, 27)
                p.c(13, 29, 13.18, 31.34, 11, 31)
                p.c(9.958, 30.06, 12.41, 27.96, 11, 28)
                p.c(10, 28, 11.19, 29.23, 10, 30)
                p.c(9, 30, 5.997, 31, 6, 26)
                p.c(6, 24, 12, 14, 12, 14)
                p.c(12, 14, 13.89, 12.1, 14, 10.5)
                p.c(13.27, 9.506, 13.5, 8.5, 13.5, 7.5)
                p.c(14.5, 6.5, 16.5, 10, 16.5, 10)
                p.l(18.5, 10)
                p.c(18.5, 10, 19.28, 8.008, 21, 7)
                p.c(22, 7, 22, 10, 22, 10)
                p.c(26, 11, 25, 15, 24, 18)
                p.z()
            })
            PieceShape { p in                             // eye and nostril
                p.ellipse(14.5, 15.5, 0.8, 1.6)
                p.ellipse(9, 25.5, 0.8, 0.8)
            }
            .fill(detail)
            if !isWhite {
                lines(PieceShape { p in                   // mane edge on the black knight
                    p.m(24.55, 10.4)
                    p.c(26.5, 11.5, 29.5, 13.5, 31.5, 17)
                    p.c(34, 21.5, 35, 28, 35, 37.5)
                }, width: 0.9)
            }
        }
    }

    // ♝ Bishop: wavy base, mitre with collar rings, ball on top, cross slit
    var bishop: some View {
        ZStack {
            solid(PieceShape { p in                       // base
                p.m(9, 36)
                p.c(12.39, 35.03, 19.11, 36.43, 22.5, 34)
                p.c(25.89, 36.43, 32.61, 35.03, 36, 36)
                p.c(36, 36, 37.65, 36.54, 39, 38)
                p.c(38.32, 38.97, 37.35, 38.99, 36, 38.5)
                p.c(32.61, 37.53, 25.89, 38.96, 22.5, 37.5)
                p.c(19.11, 38.96, 12.39, 37.53, 9, 38.5)
                p.c(7.65, 38.99, 6.68, 38.97, 6, 38)
                p.c(7.35, 36.54, 9, 36, 9, 36)
                p.z()
            })
            solid(PieceShape { p in                       // mitre and collar
                p.m(15, 32)
                p.c(17.5, 34.5, 27.5, 34.5, 30, 32)
                p.c(30.5, 30.5, 30, 30, 30, 30)
                p.c(30, 27.5, 27.5, 26, 27.5, 26)
                p.c(33, 24.5, 33.5, 14.5, 22.5, 10.5)
                p.c(11.5, 14.5, 12, 24.5, 17.5, 26)
                p.c(17.5, 26, 15, 27.5, 15, 30)
                p.c(15, 30, 14.5, 30.5, 15, 32)
                p.z()
            })
            solid(PieceShape { p in                       // ball
                p.ellipse(22.5, 8, 2.5, 2.5)
            })
            lines(PieceShape { p in                       // collar rings and cross
                p.m(17.5, 26); p.l(27.5, 26)
                p.m(15, 30); p.l(30, 30)
                p.m(22.5, 15.5); p.l(22.5, 20.5)
                p.m(20, 18); p.l(25, 18)
            })
        }
    }

    // ♛ Queen: five crown balls, spiked crown, waisted skirt with rings
    var queen: some View {
        ZStack {
            solid(PieceShape { p in                       // crown balls
                p.ellipse(6, 12, 2, 2)
                p.ellipse(14, 9, 2, 2)
                p.ellipse(22.5, 8, 2, 2)
                p.ellipse(31, 9, 2, 2)
                p.ellipse(39, 12, 2, 2)
            })
            solid(PieceShape { p in                       // spiked crown
                p.m(9, 26)
                p.c(17.5, 24.5, 30, 24.5, 36, 26)
                p.l(38.5, 13.5); p.l(31, 25); p.l(30.7, 10.9); p.l(25.5, 24.5)
                p.l(22.5, 10); p.l(19.5, 24.5); p.l(14.3, 10.9); p.l(14, 25); p.l(6.5, 13.5)
                p.z()
            })
            solid(PieceShape { p in                       // skirt and base
                p.m(9, 26)
                p.c(9, 28, 10.5, 28, 11.5, 30)
                p.c(12.5, 31.5, 12.5, 31, 12, 33.5)
                p.c(10.5, 34.5, 11, 36, 11, 36)
                p.c(9.5, 37.5, 11, 38.5, 11, 38.5)
                p.c(17.5, 39.5, 27.5, 39.5, 34, 38.5)
                p.c(34, 38.5, 35.5, 37.5, 34, 36)
                p.c(34, 36, 34.5, 34.5, 33, 33.5)
                p.c(32.5, 31, 32.5, 31.5, 33.5, 30)
                p.c(34.5, 28, 36, 28, 36, 26)
                p.c(27.5, 24.5, 17.5, 24.5, 9, 26)
                p.z()
            })
            lines(PieceShape { p in                       // rings
                p.m(11.5, 30); p.c(15, 29, 30, 29, 33.5, 30)
                p.m(12, 33.5); p.c(18, 32.5, 27, 32.5, 33, 33.5)
                p.m(11, 36); p.c(18, 35, 27, 35, 34, 36)
            })
        }
    }

    // ♚ King: cross, central bud, two-lobed body with rings
    var king: some View {
        ZStack {
            lines(PieceShape { p in                       // cross
                p.m(22.5, 11.63); p.l(22.5, 6)
                p.m(20, 8); p.l(25, 8)
            }, color: outline, width: 1.6)
            solid(PieceShape { p in                       // central bud
                p.m(22.5, 25)
                p.c(22.5, 25, 27, 17.5, 25.5, 14.5)
                p.c(25.5, 14.5, 24.5, 12, 22.5, 12)
                p.c(20.5, 12, 19.5, 14.5, 19.5, 14.5)
                p.c(18, 17.5, 22.5, 25, 22.5, 25)
                p.z()
            })
            solid(PieceShape { p in                       // body with two lobes
                p.m(12.5, 37)
                p.c(18, 40.5, 27, 40.5, 32.5, 37)
                p.l(32.5, 30)
                p.c(32.5, 30, 41.5, 25.5, 38.5, 19.5)
                p.c(34.5, 13, 25, 16, 22.5, 23.5)
                p.l(22.5, 27)
                p.l(22.5, 23.5)
                p.c(20, 16, 10.5, 13, 6.5, 19.5)
                p.c(3.5, 25.5, 12.5, 30, 12.5, 30)
                p.z()
            })
            lines(PieceShape { p in                       // rings and centre seam
                p.m(12.5, 30); p.c(18, 27, 27, 27, 32.5, 30)
                p.m(12.5, 33.5); p.c(18, 30.5, 27, 30.5, 32.5, 33.5)
                p.m(12.5, 37); p.c(18, 34, 27, 34, 32.5, 37)
                p.m(22.5, 23.5); p.l(22.5, 27)
            })
        }
    }
}

#Preview {
    ContentView()
}

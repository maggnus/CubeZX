import SwiftUI

struct IsometricCubeStateView: View {
    let moves: [CubeMove]
    
    init(moves: [CubeMove] = []) {
        self.moves = moves
    }
    
    init(scramble: String) {
        self.moves = Self.parseMoves(from: scramble)
    }
    
    private static func parseMoves(from scramble: String) -> [CubeMove] {
        let tokens = scramble.split(separator: " ").map { String($0) }
        var result: [CubeMove] = []
        
        for token in tokens {
            if let move = parseMove(token) {
                result.append(move)
            }
        }
        return result
    }
    
    private static func parseMove(_ notation: String) -> CubeMove? {
        guard !notation.isEmpty else { return nil }
        
        let isPrime = notation.contains("'")
        let isDouble = notation.contains("2")
        let direction: CubeMoveDirection = isDouble ? .double : (isPrime ? .counterClockwise : .clockwise)
        
        let base = notation.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "2", with: "")
        
        switch base {
        case "R": return CubeMove(face: .right, direction: direction)
        case "L": return CubeMove(face: .left, direction: direction)
        case "U": return CubeMove(face: .up, direction: direction)
        case "D": return CubeMove(face: .down, direction: direction)
        case "F": return CubeMove(face: .front, direction: direction)
        case "B": return CubeMove(face: .back, direction: direction)
        case "M": return CubeMove(slice: .middle, direction: direction)
        case "E": return CubeMove(slice: .equator, direction: direction)
        case "S": return CubeMove(slice: .standing, direction: direction)
        case "X", "x": return CubeMove(rotation: .x, direction: direction)
        case "Y", "y": return CubeMove(rotation: .y, direction: direction)
        case "Z", "z": return CubeMove(rotation: .z, direction: direction)
        case "r": return CubeMove(wide: .rightWide, direction: direction)
        case "l": return CubeMove(wide: .leftWide, direction: direction)
        case "u": return CubeMove(wide: .upWide, direction: direction)
        case "d": return CubeMove(wide: .downWide, direction: direction)
        case "f": return CubeMove(wide: .frontWide, direction: direction)
        case "b": return CubeMove(wide: .backWide, direction: direction)
        default: return nil
        }
    }
    
    var body: some View {
        Canvas { context, size in
            let state = computeState()
            let s = min(size.width, size.height)
            let cx = size.width / 2
            let cy = size.height / 2 + s * 0.05
            let unit = s * 0.11
            
            let iso: (CGFloat, CGFloat, CGFloat) -> CGPoint = { x, y, z in
                CGPoint(
                    x: cx + (x - z) * 0.866 * unit,
                    y: cy - y * unit + (x + z) * 0.5 * unit
                )
            }
            
            for row in 0..<3 {
                for col in 0..<3 {
                    let x = CGFloat(col - 1)
                    let z = CGFloat(row - 1)
                    
                    let tl = iso(x - 0.45, 1.5, z - 0.45)
                    let tr = iso(x + 0.45, 1.5, z - 0.45)
                    let bl = iso(x - 0.45, 1.5, z + 0.45)
                    let br = iso(x + 0.45, 1.5, z + 0.45)
                    
                    var path = Path()
                    path.move(to: tl)
                    path.addLine(to: tr)
                    path.addLine(to: br)
                    path.addLine(to: bl)
                    path.closeSubpath()
                    
                    let color = state.upFace[row][col]
                    context.fill(path, with: .color(color))
                    context.stroke(path, with: .color(.black.opacity(0.6)), lineWidth: 0.5)
                }
            }
            
            for row in 0..<3 {
                for col in 0..<3 {
                    let x: CGFloat = 1.5
                    let y = CGFloat(1 - row)
                    let z = CGFloat(col - 1)
                    
                    let tl = iso(x, y + 0.45, z - 0.45)
                    let tr = iso(x, y + 0.45, z + 0.45)
                    let bl = iso(x, y - 0.45, z - 0.45)
                    let br = iso(x, y - 0.45, z + 0.45)
                    
                    var path = Path()
                    path.move(to: tl)
                    path.addLine(to: tr)
                    path.addLine(to: br)
                    path.addLine(to: bl)
                    path.closeSubpath()
                    
                    let color = state.rightFace[row][col]
                    context.fill(path, with: .color(color))
                    context.stroke(path, with: .color(.black.opacity(0.6)), lineWidth: 0.5)
                }
            }
            
            for row in 0..<3 {
                for col in 0..<3 {
                    let x = CGFloat(col - 1)
                    let y = CGFloat(1 - row)
                    let z: CGFloat = 1.5
                    
                    let tl = iso(x - 0.45, y + 0.45, z)
                    let tr = iso(x + 0.45, y + 0.45, z)
                    let bl = iso(x - 0.45, y - 0.45, z)
                    let br = iso(x + 0.45, y - 0.45, z)
                    
                    var path = Path()
                    path.move(to: tl)
                    path.addLine(to: tr)
                    path.addLine(to: br)
                    path.addLine(to: bl)
                    path.closeSubpath()
                    
                    let color = state.frontFace[row][col]
                    context.fill(path, with: .color(color))
                    context.stroke(path, with: .color(.black.opacity(0.6)), lineWidth: 0.5)
                }
            }
        }
    }
    
    private func computeState() -> VisualCubeState {
        var state = VisualCubeState.solved()
        for move in moves {
            state.apply(move)
        }
        return state
    }
}

struct VisualCubeState {
    var upFace: [[Color]]
    var downFace: [[Color]]
    var frontFace: [[Color]]
    var backFace: [[Color]]
    var leftFace: [[Color]]
    var rightFace: [[Color]]
    
    static let yellow = Color.yellow
    static let white = Color.white
    static let blue = Color.blue
    static let green = Color.green
    static let orange = Color.orange
    static let red = Color.red
    
    static func solved() -> VisualCubeState {
        VisualCubeState(
            upFace: Array(repeating: Array(repeating: white, count: 3), count: 3),
            downFace: Array(repeating: Array(repeating: yellow, count: 3), count: 3),
            frontFace: Array(repeating: Array(repeating: green, count: 3), count: 3),
            backFace: Array(repeating: Array(repeating: blue, count: 3), count: 3),
            leftFace: Array(repeating: Array(repeating: orange, count: 3), count: 3),
            rightFace: Array(repeating: Array(repeating: red, count: 3), count: 3)
        )
    }
    
    mutating func apply(_ move: CubeMove) {
        let times = move.direction == .double ? 2 : 1
        let clockwise = move.direction != .counterClockwise
        
        for _ in 0..<times {
            switch move.moveType {
            case .face(let face):
                applyFaceMove(face, clockwise: clockwise)
            case .slice(let slice):
                applySliceMove(slice, clockwise: clockwise)
            case .rotation(let rotation):
                applyRotation(rotation, clockwise: clockwise)
            case .wide(let wide):
                applyWideMove(wide, clockwise: clockwise)
            }
        }
    }
    
    private mutating func applyFaceMove(_ face: CubeMoveFace, clockwise: Bool) {
        switch face {
        case .right:
            rotateFaceCW(&rightFace, clockwise: clockwise)
            let temp = [upFace[0][2], upFace[1][2], upFace[2][2]]
            if clockwise {
                for i in 0..<3 { upFace[i][2] = frontFace[i][2] }
                for i in 0..<3 { frontFace[i][2] = downFace[i][2] }
                for i in 0..<3 { downFace[i][2] = backFace[2-i][0] }
                for i in 0..<3 { backFace[i][0] = temp[2-i] }
            } else {
                for i in 0..<3 { upFace[i][2] = backFace[2-i][0] }
                for i in 0..<3 { backFace[i][0] = downFace[2-i][2] }
                for i in 0..<3 { downFace[i][2] = frontFace[i][2] }
                for i in 0..<3 { frontFace[i][2] = temp[i] }
            }
            
        case .left:
            rotateFaceCW(&leftFace, clockwise: clockwise)
            let temp = [upFace[0][0], upFace[1][0], upFace[2][0]]
            if clockwise {
                for i in 0..<3 { upFace[i][0] = backFace[2-i][2] }
                for i in 0..<3 { backFace[i][2] = downFace[2-i][0] }
                for i in 0..<3 { downFace[i][0] = frontFace[i][0] }
                for i in 0..<3 { frontFace[i][0] = temp[i] }
            } else {
                for i in 0..<3 { upFace[i][0] = frontFace[i][0] }
                for i in 0..<3 { frontFace[i][0] = downFace[i][0] }
                for i in 0..<3 { downFace[i][0] = backFace[2-i][2] }
                for i in 0..<3 { backFace[i][2] = temp[2-i] }
            }
            
        case .up:
            rotateFaceCW(&upFace, clockwise: clockwise)
            let temp = frontFace[0]
            if clockwise {
                // U clockwise: F→L→B→R→F (pieces move counterclockwise when viewed from above)
                frontFace[0] = leftFace[0]
                leftFace[0] = backFace[0]
                backFace[0] = rightFace[0]
                rightFace[0] = temp
            } else {
                // U counterclockwise: F→R→B→L→F
                frontFace[0] = rightFace[0]
                rightFace[0] = backFace[0]
                backFace[0] = leftFace[0]
                leftFace[0] = temp
            }
            
        case .down:
            rotateFaceCW(&downFace, clockwise: clockwise)
            let temp = frontFace[2]
            if clockwise {
                // D clockwise: F→R→B→L→F (pieces move clockwise when viewed from below)
                frontFace[2] = rightFace[2]
                rightFace[2] = backFace[2]
                backFace[2] = leftFace[2]
                leftFace[2] = temp
            } else {
                // D counterclockwise: F→L→B→R→F
                frontFace[2] = leftFace[2]
                leftFace[2] = backFace[2]
                backFace[2] = rightFace[2]
                rightFace[2] = temp
            }
            
        case .front:
            rotateFaceCW(&frontFace, clockwise: clockwise)
            let tempU = upFace[2]
            if clockwise {
                upFace[2] = [leftFace[2][2], leftFace[1][2], leftFace[0][2]]
                leftFace[0][2] = downFace[0][0]
                leftFace[1][2] = downFace[0][1]
                leftFace[2][2] = downFace[0][2]
                downFace[0] = [rightFace[2][0], rightFace[1][0], rightFace[0][0]]
                rightFace[0][0] = tempU[0]
                rightFace[1][0] = tempU[1]
                rightFace[2][0] = tempU[2]
            } else {
                upFace[2] = [rightFace[0][0], rightFace[1][0], rightFace[2][0]]
                rightFace[0][0] = downFace[0][2]
                rightFace[1][0] = downFace[0][1]
                rightFace[2][0] = downFace[0][0]
                downFace[0] = [leftFace[0][2], leftFace[1][2], leftFace[2][2]]
                leftFace[0][2] = tempU[2]
                leftFace[1][2] = tempU[1]
                leftFace[2][2] = tempU[0]
            }
            
        case .back:
            rotateFaceCW(&backFace, clockwise: clockwise)
            let tempU = upFace[0]
            if clockwise {
                upFace[0] = [rightFace[0][2], rightFace[1][2], rightFace[2][2]]
                rightFace[0][2] = downFace[2][2]
                rightFace[1][2] = downFace[2][1]
                rightFace[2][2] = downFace[2][0]
                downFace[2] = [leftFace[0][0], leftFace[1][0], leftFace[2][0]]
                leftFace[0][0] = tempU[2]
                leftFace[1][0] = tempU[1]
                leftFace[2][0] = tempU[0]
            } else {
                upFace[0] = [leftFace[2][0], leftFace[1][0], leftFace[0][0]]
                leftFace[0][0] = downFace[2][0]
                leftFace[1][0] = downFace[2][1]
                leftFace[2][0] = downFace[2][2]
                downFace[2] = [rightFace[2][2], rightFace[1][2], rightFace[0][2]]
                rightFace[0][2] = tempU[0]
                rightFace[1][2] = tempU[1]
                rightFace[2][2] = tempU[2]
            }
        }
    }
    
    private mutating func applySliceMove(_ slice: CubeSliceMove, clockwise: Bool) {
        switch slice {
        case .middle:
            let temp = [upFace[0][1], upFace[1][1], upFace[2][1]]
            if clockwise {
                for i in 0..<3 { upFace[i][1] = backFace[2-i][1] }
                for i in 0..<3 { backFace[i][1] = downFace[2-i][1] }
                for i in 0..<3 { downFace[i][1] = frontFace[i][1] }
                for i in 0..<3 { frontFace[i][1] = temp[i] }
            } else {
                for i in 0..<3 { upFace[i][1] = frontFace[i][1] }
                for i in 0..<3 { frontFace[i][1] = downFace[i][1] }
                for i in 0..<3 { downFace[i][1] = backFace[2-i][1] }
                for i in 0..<3 { backFace[i][1] = temp[2-i] }
            }
            
        case .equator:
            // E follows D direction: clockwise moves F→R→B→L→F
            let temp = frontFace[1]
            if clockwise {
                frontFace[1] = rightFace[1]
                rightFace[1] = backFace[1]
                backFace[1] = leftFace[1]
                leftFace[1] = temp
            } else {
                frontFace[1] = leftFace[1]
                leftFace[1] = backFace[1]
                backFace[1] = rightFace[1]
                rightFace[1] = temp
            }
            
        case .standing:
            let tempU = upFace[1]
            if clockwise {
                upFace[1] = [leftFace[2][1], leftFace[1][1], leftFace[0][1]]
                leftFace[0][1] = downFace[1][0]
                leftFace[1][1] = downFace[1][1]
                leftFace[2][1] = downFace[1][2]
                downFace[1] = [rightFace[2][1], rightFace[1][1], rightFace[0][1]]
                rightFace[0][1] = tempU[0]
                rightFace[1][1] = tempU[1]
                rightFace[2][1] = tempU[2]
            } else {
                upFace[1] = [rightFace[0][1], rightFace[1][1], rightFace[2][1]]
                rightFace[0][1] = downFace[1][2]
                rightFace[1][1] = downFace[1][1]
                rightFace[2][1] = downFace[1][0]
                downFace[1] = [leftFace[0][1], leftFace[1][1], leftFace[2][1]]
                leftFace[0][1] = tempU[2]
                leftFace[1][1] = tempU[1]
                leftFace[2][1] = tempU[0]
            }
        }
    }
    
    private mutating func applyRotation(_ rotation: CubeRotation, clockwise: Bool) {
        switch rotation {
        case .x:
            if clockwise {
                var temp = upFace
                upFace = frontFace
                frontFace = downFace
                rotateFaceCW(&backFace, clockwise: true)
                rotateFaceCW(&backFace, clockwise: true)
                downFace = backFace
                rotateFaceCW(&temp, clockwise: true)
                rotateFaceCW(&temp, clockwise: true)
                backFace = temp
                rotateFaceCW(&rightFace, clockwise: true)
                rotateFaceCW(&leftFace, clockwise: false)
            } else {
                var temp = upFace
                rotateFaceCW(&backFace, clockwise: true)
                rotateFaceCW(&backFace, clockwise: true)
                upFace = backFace
                backFace = downFace
                rotateFaceCW(&backFace, clockwise: true)
                rotateFaceCW(&backFace, clockwise: true)
                downFace = frontFace
                frontFace = temp
                rotateFaceCW(&rightFace, clockwise: false)
                rotateFaceCW(&leftFace, clockwise: true)
            }
            
        case .y:
            // y follows U direction: clockwise moves F→L→B→R→F
            if clockwise {
                let temp = frontFace
                frontFace = leftFace
                leftFace = backFace
                backFace = rightFace
                rightFace = temp
                rotateFaceCW(&upFace, clockwise: true)
                rotateFaceCW(&downFace, clockwise: false)
            } else {
                let temp = frontFace
                frontFace = rightFace
                rightFace = backFace
                backFace = leftFace
                leftFace = temp
                rotateFaceCW(&upFace, clockwise: false)
                rotateFaceCW(&downFace, clockwise: true)
            }
            
        case .z:
            if clockwise {
                let temp = upFace
                upFace = leftFace
                rotateFaceCW(&upFace, clockwise: true)
                leftFace = downFace
                rotateFaceCW(&leftFace, clockwise: true)
                downFace = rightFace
                rotateFaceCW(&downFace, clockwise: true)
                rightFace = temp
                rotateFaceCW(&rightFace, clockwise: true)
                rotateFaceCW(&frontFace, clockwise: true)
                rotateFaceCW(&backFace, clockwise: false)
            } else {
                let temp = upFace
                upFace = rightFace
                rotateFaceCW(&upFace, clockwise: false)
                rightFace = downFace
                rotateFaceCW(&rightFace, clockwise: false)
                downFace = leftFace
                rotateFaceCW(&downFace, clockwise: false)
                leftFace = temp
                rotateFaceCW(&leftFace, clockwise: false)
                rotateFaceCW(&frontFace, clockwise: false)
                rotateFaceCW(&backFace, clockwise: true)
            }
        }
    }
    
    private mutating func applyWideMove(_ wide: CubeWideFace, clockwise: Bool) {
        switch wide {
        case .rightWide:
            applyFaceMove(.right, clockwise: clockwise)
            applySliceMove(.middle, clockwise: !clockwise)
        case .leftWide:
            applyFaceMove(.left, clockwise: clockwise)
            applySliceMove(.middle, clockwise: clockwise)
        case .upWide:
            applyFaceMove(.up, clockwise: clockwise)
            applySliceMove(.equator, clockwise: !clockwise)
        case .downWide:
            applyFaceMove(.down, clockwise: clockwise)
            applySliceMove(.equator, clockwise: clockwise)
        case .frontWide:
            applyFaceMove(.front, clockwise: clockwise)
            applySliceMove(.standing, clockwise: clockwise)
        case .backWide:
            applyFaceMove(.back, clockwise: clockwise)
            applySliceMove(.standing, clockwise: !clockwise)
        }
    }
    
    private func rotateFaceCW(_ face: inout [[Color]], clockwise: Bool) {
        let original = face
        if clockwise {
            for i in 0..<3 {
                for j in 0..<3 {
                    face[j][2-i] = original[i][j]
                }
            }
        } else {
            for i in 0..<3 {
                for j in 0..<3 {
                    face[2-j][i] = original[i][j]
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Solved")
        IsometricCubeStateView()
            .frame(width: 100, height: 100)
        
        Text("R U R' U'")
        IsometricCubeStateView(scramble: "R U R' U'")
            .frame(width: 100, height: 100)
        
        Text("Superflip")
        IsometricCubeStateView(scramble: "U R2 F B R B2 R U2 L B2 R U' D' R2 F R' L B2 U2 F2")
            .frame(width: 100, height: 100)
    }
    .padding()
}

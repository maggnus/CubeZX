import Foundation

enum CubeFace: String, CaseIterable, Codable {
    case up
    case down
    case left
    case right
    case front
    case back
}

enum CubeColor: String, CaseIterable, Codable {
    case white
    case yellow
    case orange
    case red
    case green
    case blue
}

struct CubeState: Codable, Equatable {
    var facelets: [CubeColor]
    var moveHistory: [CubeMove]
    var lastUpdated: Date

    init(facelets: [CubeColor], moveHistory: [CubeMove] = [], lastUpdated: Date = Date()) {
        self.facelets = facelets
        self.moveHistory = moveHistory
        self.lastUpdated = lastUpdated
    }

    static func solved() -> CubeState {
        var facelets: [CubeColor] = []
        for face in CubeFace.allCases {
            let color = CubeState.defaultColor(for: face)
            facelets.append(contentsOf: Array(repeating: color, count: 9))
        }
        return CubeState(facelets: facelets)
    }

    mutating func apply(_ move: CubeMove) {
        moveHistory.append(move)
        lastUpdated = Date()
        
        let times = move.direction == .double ? 2 : 1
        let clockwise = move.direction != .counterClockwise
        
        for _ in 0..<times {
            switch move.moveType {
            case .face(let face):
                rotateFace(face, clockwise: clockwise)
            case .slice(let slice):
                applySliceMove(slice, clockwise: clockwise)
            case .rotation(let rotation):
                applyRotation(rotation, clockwise: clockwise)
            case .wide(let wide):
                applyWideMove(wide, clockwise: clockwise)
            }
        }
    }
    
    private mutating func rotateFace(_ face: CubeMoveFace, clockwise: Bool) {
        let faceIndex = CubeState.faceIndex(for: face)
        let start = faceIndex * 9
        
        var facelet = Array(facelets[start..<start+9])
        if clockwise {
            facelet = [facelet[6], facelet[3], facelet[0],
                       facelet[7], facelet[4], facelet[1],
                       facelet[8], facelet[5], facelet[2]]
        } else {
            facelet = [facelet[2], facelet[5], facelet[8],
                       facelet[1], facelet[4], facelet[7],
                       facelet[0], facelet[3], facelet[6]]
        }
        for i in 0..<9 {
            facelets[start + i] = facelet[i]
        }
        
        rotateAdjacentEdges(face, clockwise: clockwise)
    }
    
    private mutating func rotateAdjacentEdges(_ face: CubeMoveFace, clockwise: Bool) {
        let cubeFace: CubeFace
        switch face {
        case .up: cubeFace = .up
        case .down: cubeFace = .down
        case .left: cubeFace = .left
        case .right: cubeFace = .right
        case .front: cubeFace = .front
        case .back: cubeFace = .back
        }
        let edges: [(CubeFace, [Int])]
        
        switch cubeFace {
        case .up:
            edges = [(.front, [0,1,2]), (.right, [0,1,2]), (.back, [0,1,2]), (.left, [0,1,2])]
        case .down:
            edges = [(.front, [6,7,8]), (.left, [6,7,8]), (.back, [6,7,8]), (.right, [6,7,8])]
        case .front:
            edges = [(.up, [6,7,8]), (.right, [0,3,6]), (.down, [2,1,0]), (.left, [8,5,2])]
        case .back:
            edges = [(.up, [2,1,0]), (.left, [0,3,6]), (.down, [6,7,8]), (.right, [8,5,2])]
        case .left:
            edges = [(.up, [0,3,6]), (.front, [0,3,6]), (.down, [0,3,6]), (.back, [8,5,2])]
        case .right:
            edges = [(.up, [8,5,2]), (.back, [0,3,6]), (.down, [8,5,2]), (.front, [8,5,2])]
        }
        
        var strips: [[CubeColor]] = edges.map { face, indices in
            let start = CubeState.faceIndex(for: face) * 9
            return indices.map { facelets[start + $0] }
        }
        
        if clockwise {
            strips = [strips[3], strips[0], strips[1], strips[2]]
        } else {
            strips = [strips[1], strips[2], strips[3], strips[0]]
        }
        
        for (i, (face, indices)) in edges.enumerated() {
            let start = CubeState.faceIndex(for: face) * 9
            for (j, idx) in indices.enumerated() {
                facelets[start + idx] = strips[i][j]
            }
        }
    }
    
    private static func faceIndex(for face: CubeMoveFace) -> Int {
        switch face {
        case .up: return 0
        case .down: return 1
        case .left: return 2
        case .right: return 3
        case .front: return 4
        case .back: return 5
        }
    }
    
    private static func faceIndex(for face: CubeFace) -> Int {
        switch face {
        case .up: return 0
        case .down: return 1
        case .left: return 2
        case .right: return 3
        case .front: return 4
        case .back: return 5
        }
    }

    private mutating func applySliceMove(_ slice: CubeSliceMove, clockwise: Bool) {
        var grid = FaceGrid(facelets: facelets)
        grid.applySliceMove(slice, clockwise: clockwise)
        facelets = grid.toFacelets()
    }

    private mutating func applyRotation(_ rotation: CubeRotation, clockwise: Bool) {
        var grid = FaceGrid(facelets: facelets)
        grid.applyRotation(rotation, clockwise: clockwise)
        facelets = grid.toFacelets()
    }

    private mutating func applyWideMove(_ wide: CubeWideFace, clockwise: Bool) {
        var grid = FaceGrid(facelets: facelets)
        grid.applyWideMove(wide, clockwise: clockwise)
        facelets = grid.toFacelets()
    }

    static func defaultColor(for face: CubeFace) -> CubeColor {
        switch face {
        case .up:
            return .white    // White on top
        case .down:
            return .yellow   // Yellow on bottom
        case .left:
            return .orange   // Orange on left
        case .right:
            return .red      // Red on right
        case .front:
            return .green    // Green on front
        case .back:
            return .blue     // Blue on back
        }
    }
}

private struct FaceGrid {
    var up: [[CubeColor]]
    var down: [[CubeColor]]
    var left: [[CubeColor]]
    var right: [[CubeColor]]
    var front: [[CubeColor]]
    var back: [[CubeColor]]

    init(facelets: [CubeColor]) {
        func face(_ offset: Int) -> [[CubeColor]] {
            var result = Array(repeating: Array(repeating: CubeColor.white, count: 3), count: 3)
            for row in 0..<3 {
                for col in 0..<3 {
                    result[row][col] = facelets[offset + row * 3 + col]
                }
            }
            return result
        }

        up = face(0)
        down = face(9)
        left = face(18)
        right = face(27)
        front = face(36)
        back = face(45)
    }

    func toFacelets() -> [CubeColor] {
        var result = Array(repeating: CubeColor.white, count: 54)
        func write(_ face: [[CubeColor]], _ offset: Int) {
            for row in 0..<3 {
                for col in 0..<3 {
                    result[offset + row * 3 + col] = face[row][col]
                }
            }
        }

        write(up, 0)
        write(down, 9)
        write(left, 18)
        write(right, 27)
        write(front, 36)
        write(back, 45)
        return result
    }

    mutating func applySliceMove(_ slice: CubeSliceMove, clockwise: Bool) {
        switch slice {
        case .middle:
            let temp = [up[0][1], up[1][1], up[2][1]]
            if clockwise {
                for i in 0..<3 { up[i][1] = back[2 - i][1] }
                for i in 0..<3 { back[i][1] = down[2 - i][1] }
                for i in 0..<3 { down[i][1] = front[i][1] }
                for i in 0..<3 { front[i][1] = temp[i] }
            } else {
                for i in 0..<3 { up[i][1] = front[i][1] }
                for i in 0..<3 { front[i][1] = down[i][1] }
                for i in 0..<3 { down[i][1] = back[2 - i][1] }
                for i in 0..<3 { back[i][1] = temp[2 - i] }
            }
        case .equator:
            let temp = front[1]
            if clockwise {
                front[1] = left[1]
                left[1] = back[1]
                back[1] = right[1]
                right[1] = temp
            } else {
                front[1] = right[1]
                right[1] = back[1]
                back[1] = left[1]
                left[1] = temp
            }
        case .standing:
            let temp = up[1]
            if clockwise {
                up[1] = [left[2][1], left[1][1], left[0][1]]
                left[0][1] = down[1][0]
                left[1][1] = down[1][1]
                left[2][1] = down[1][2]
                down[1] = [right[2][1], right[1][1], right[0][1]]
                right[0][1] = temp[0]
                right[1][1] = temp[1]
                right[2][1] = temp[2]
            } else {
                up[1] = [right[0][1], right[1][1], right[2][1]]
                right[0][1] = down[1][2]
                right[1][1] = down[1][1]
                right[2][1] = down[1][0]
                down[1] = [left[0][1], left[1][1], left[2][1]]
                left[0][1] = temp[2]
                left[1][1] = temp[1]
                left[2][1] = temp[0]
            }
        }
    }

    mutating func applyRotation(_ rotation: CubeRotation, clockwise: Bool) {
        switch rotation {
        case .x:
            if clockwise {
                let temp = up
                up = front
                front = down
                back = rotated(back, clockwise: true)
                back = rotated(back, clockwise: true)
                down = back
                var tempBack = temp
                tempBack = rotated(tempBack, clockwise: true)
                tempBack = rotated(tempBack, clockwise: true)
                back = tempBack
                right = rotated(right, clockwise: true)
                left = rotated(left, clockwise: false)
            } else {
                let temp = up
                back = rotated(back, clockwise: true)
                back = rotated(back, clockwise: true)
                up = back
                back = down
                back = rotated(back, clockwise: true)
                back = rotated(back, clockwise: true)
                down = front
                front = temp
                right = rotated(right, clockwise: false)
                left = rotated(left, clockwise: true)
            }
        case .y:
            if clockwise {
                let temp = front
                front = right
                right = back
                back = left
                left = temp
                up = rotated(up, clockwise: true)
                down = rotated(down, clockwise: false)
            } else {
                let temp = front
                front = left
                left = back
                back = right
                right = temp
                up = rotated(up, clockwise: false)
                down = rotated(down, clockwise: true)
            }
        case .z:
            if clockwise {
                let temp = up
                up = left
                up = rotated(up, clockwise: true)
                left = down
                left = rotated(left, clockwise: true)
                down = right
                down = rotated(down, clockwise: true)
                right = temp
                right = rotated(right, clockwise: true)
                front = rotated(front, clockwise: true)
                back = rotated(back, clockwise: false)
            } else {
                let temp = up
                up = right
                up = rotated(up, clockwise: false)
                right = down
                right = rotated(right, clockwise: false)
                down = left
                down = rotated(down, clockwise: false)
                left = temp
                left = rotated(left, clockwise: false)
                front = rotated(front, clockwise: false)
                back = rotated(back, clockwise: true)
            }
        }
    }

    mutating func applyWideMove(_ wide: CubeWideFace, clockwise: Bool) {
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

    mutating func applyFaceMove(_ face: CubeMoveFace, clockwise: Bool) {
        switch face {
        case .right:
            right = rotated(right, clockwise: clockwise)
            let temp = [up[0][2], up[1][2], up[2][2]]
            if clockwise {
                for i in 0..<3 { up[i][2] = front[i][2] }
                for i in 0..<3 { front[i][2] = down[i][2] }
                for i in 0..<3 { down[i][2] = back[2 - i][0] }
                for i in 0..<3 { back[i][0] = temp[2 - i] }
            } else {
                for i in 0..<3 { up[i][2] = back[2 - i][0] }
                for i in 0..<3 { back[i][0] = down[2 - i][2] }
                for i in 0..<3 { down[i][2] = front[i][2] }
                for i in 0..<3 { front[i][2] = temp[i] }
            }
        case .left:
            left = rotated(left, clockwise: clockwise)
            let temp = [up[0][0], up[1][0], up[2][0]]
            if clockwise {
                for i in 0..<3 { up[i][0] = back[2 - i][2] }
                for i in 0..<3 { back[i][2] = down[2 - i][0] }
                for i in 0..<3 { down[i][0] = front[i][0] }
                for i in 0..<3 { front[i][0] = temp[i] }
            } else {
                for i in 0..<3 { up[i][0] = front[i][0] }
                for i in 0..<3 { front[i][0] = down[i][0] }
                for i in 0..<3 { down[i][0] = back[2 - i][2] }
                for i in 0..<3 { back[i][2] = temp[2 - i] }
            }
        case .up:
            up = rotated(up, clockwise: clockwise)
            let temp = front[0]
            if clockwise {
                front[0] = right[0]
                right[0] = back[0]
                back[0] = left[0]
                left[0] = temp
            } else {
                front[0] = left[0]
                left[0] = back[0]
                back[0] = right[0]
                right[0] = temp
            }
        case .down:
            down = rotated(down, clockwise: clockwise)
            let temp = front[2]
            if clockwise {
                front[2] = left[2]
                left[2] = back[2]
                back[2] = right[2]
                right[2] = temp
            } else {
                front[2] = right[2]
                right[2] = back[2]
                back[2] = left[2]
                left[2] = temp
            }
        case .front:
            front = rotated(front, clockwise: clockwise)
            let tempU = up[2]
            if clockwise {
                up[2] = [left[2][2], left[1][2], left[0][2]]
                left[0][2] = down[0][0]
                left[1][2] = down[0][1]
                left[2][2] = down[0][2]
                down[0] = [right[2][0], right[1][0], right[0][0]]
                right[0][0] = tempU[0]
                right[1][0] = tempU[1]
                right[2][0] = tempU[2]
            } else {
                up[2] = [right[0][0], right[1][0], right[2][0]]
                right[0][0] = down[0][2]
                right[1][0] = down[0][1]
                right[2][0] = down[0][0]
                down[0] = [left[0][2], left[1][2], left[2][2]]
                left[0][2] = tempU[2]
                left[1][2] = tempU[1]
                left[2][2] = tempU[0]
            }
        case .back:
            back = rotated(back, clockwise: clockwise)
            let tempU = up[0]
            if clockwise {
                up[0] = [right[0][2], right[1][2], right[2][2]]
                right[0][2] = down[2][2]
                right[1][2] = down[2][1]
                right[2][2] = down[2][0]
                down[2] = [left[0][0], left[1][0], left[2][0]]
                left[0][0] = tempU[2]
                left[1][0] = tempU[1]
                left[2][0] = tempU[0]
            } else {
                up[0] = [left[2][0], left[1][0], left[0][0]]
                left[0][0] = down[2][0]
                left[1][0] = down[2][1]
                left[2][0] = down[2][2]
                down[2] = [right[2][2], right[1][2], right[0][2]]
                right[0][2] = tempU[0]
                right[1][2] = tempU[1]
                right[2][2] = tempU[2]
            }
        }
    }

    private func rotated(_ face: [[CubeColor]], clockwise: Bool) -> [[CubeColor]] {
        var result = face
        if clockwise {
            for i in 0..<3 {
                for j in 0..<3 {
                    result[j][2 - i] = face[i][j]
                }
            }
        } else {
            for i in 0..<3 {
                for j in 0..<3 {
                    result[2 - j][i] = face[i][j]
                }
            }
        }
        return result
    }
}

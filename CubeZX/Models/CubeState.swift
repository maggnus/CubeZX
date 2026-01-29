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
            rotateFace(move.face, clockwise: clockwise)
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
            edges = [(.front, [0,1,2]), (.left, [0,1,2]), (.back, [0,1,2]), (.right, [0,1,2])]
        case .down:
            edges = [(.front, [6,7,8]), (.right, [6,7,8]), (.back, [6,7,8]), (.left, [6,7,8])]
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

    static func defaultColor(for face: CubeFace) -> CubeColor {
        switch face {
        case .up:
            return .white
        case .down:
            return .yellow
        case .left:
            return .orange
        case .right:
            return .red
        case .front:
            return .green
        case .back:
            return .blue
        }
    }
}

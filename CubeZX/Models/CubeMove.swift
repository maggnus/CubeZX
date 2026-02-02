import Foundation

enum CubeMoveFace: String, CaseIterable, Codable {
    case up = "U"
    case down = "D"
    case left = "L"
    case right = "R"
    case front = "F"
    case back = "B"
}

enum CubeSliceMove: String, CaseIterable, Codable {
    case middle = "M"   // Between L and R, follows L direction
    case equator = "E"  // Between U and D, follows D direction
    case standing = "S" // Between F and B, follows F direction
}

enum CubeRotation: String, CaseIterable, Codable {
    case x = "x"  // Rotate entire cube on R axis
    case y = "y"  // Rotate entire cube on U axis
    case z = "z"  // Rotate entire cube on F axis
}

enum CubeWideFace: String, CaseIterable, Codable {
    case upWide = "u"    // U + E'
    case downWide = "d"  // D + E
    case leftWide = "l"  // L + M
    case rightWide = "r" // R + M'
    case frontWide = "f" // F + S
    case backWide = "b"  // B + S'
}

enum CubeMoveDirection: String, Codable {
    case clockwise
    case counterClockwise
    case double

    var notationSuffix: String {
        switch self {
        case .clockwise:
            return ""
        case .counterClockwise:
            return "'"
        case .double:
            return "2"
        }
    }
}

enum CubeMoveType: Codable, Hashable {
    case face(CubeMoveFace)
    case slice(CubeSliceMove)
    case rotation(CubeRotation)
    case wide(CubeWideFace)
    
    var notation: String {
        switch self {
        case .face(let f): return f.rawValue
        case .slice(let s): return s.rawValue
        case .rotation(let r): return r.rawValue
        case .wide(let w): return w.rawValue
        }
    }
}

struct CubeMove: Hashable, Codable, Identifiable {
    let id = UUID()
    let moveType: CubeMoveType
    let direction: CubeMoveDirection
    let timestamp: Date
    let seq: UInt8  // Sequence number from cube protocol (0-255)

    init(face: CubeMoveFace, direction: CubeMoveDirection, timestamp: Date = Date(), seq: UInt8 = 0) {
        self.moveType = .face(face)
        self.direction = direction
        self.timestamp = timestamp
        self.seq = seq
    }
    
    init(slice: CubeSliceMove, direction: CubeMoveDirection, timestamp: Date = Date(), seq: UInt8 = 0) {
        self.moveType = .slice(slice)
        self.direction = direction
        self.timestamp = timestamp
        self.seq = seq
    }
    
    init(rotation: CubeRotation, direction: CubeMoveDirection, timestamp: Date = Date(), seq: UInt8 = 0) {
        self.moveType = .rotation(rotation)
        self.direction = direction
        self.timestamp = timestamp
        self.seq = seq
    }
    
    init(wide: CubeWideFace, direction: CubeMoveDirection, timestamp: Date = Date(), seq: UInt8 = 0) {
        self.moveType = .wide(wide)
        self.direction = direction
        self.timestamp = timestamp
        self.seq = seq
    }

    var notation: String {
        "\(moveType.notation)\(direction.notationSuffix)"
    }
    
    var face: CubeMoveFace {
        if case .face(let f) = moveType {
            return f
        }
        return .front
    }
}

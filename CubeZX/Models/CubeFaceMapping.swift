import Foundation

struct CubeFaceMapping {
    var front: CubeMoveFace = .back
    var back: CubeMoveFace = .front
    var up: CubeMoveFace = .up
    var down: CubeMoveFace = .down
    var left: CubeMoveFace = .left
    var right: CubeMoveFace = .right
    
    func actualFace(for inputFace: CubeMoveFace) -> CubeMoveFace {
        switch inputFace {
        case .front: return front
        case .back: return back
        case .up: return up
        case .down: return down
        case .left: return left
        case .right: return right
        }
    }
    
    mutating func applyRotation(_ rotation: CubeRotation, direction: CubeMoveDirection) {
        let times = direction == .double ? 2 : 1
        let clockwise = direction != .counterClockwise
        
        for _ in 0..<times {
            switch rotation {
            case .x:
                if clockwise {
                    rotateX()
                } else {
                    rotateXPrime()
                }
            case .y:
                if clockwise {
                    rotateY()
                } else {
                    rotateYPrime()
                }
            case .z:
                if clockwise {
                    rotateZ()
                } else {
                    rotateZPrime()
                }
            }
        }
    }
    
    private mutating func rotateX() {
        let oldFront = front
        front = down
        down = back
        back = up
        up = oldFront
    }
    
    private mutating func rotateXPrime() {
        let oldFront = front
        front = up
        up = back
        back = down
        down = oldFront
    }
    
    private mutating func rotateY() {
        let oldFront = front
        front = right
        right = back
        back = left
        left = oldFront
    }
    
    private mutating func rotateYPrime() {
        let oldFront = front
        front = left
        left = back
        back = right
        right = oldFront
    }
    
    private mutating func rotateZ() {
        let oldUp = up
        up = left
        left = down
        down = right
        right = oldUp
    }
    
    private mutating func rotateZPrime() {
        let oldUp = up
        up = right
        right = down
        down = left
        left = oldUp
    }
    
    var description: String {
        "F=\(front.rawValue) B=\(back.rawValue) U=\(up.rawValue) D=\(down.rawValue) L=\(left.rawValue) R=\(right.rawValue)"
    }
}

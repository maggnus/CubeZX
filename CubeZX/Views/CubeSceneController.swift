import SceneKit
import Foundation

final class CubeSceneController {
    let scene: SCNScene
    private let cubeRoot: SCNNode
    private var cubies: [String: SCNNode] = [:]
    private let cubieSize: CGFloat = 0.3
    private var isAnimating = false
    
    // Animation queue to prevent losing moves
    private var animationQueue: [(move: CubeMove, completion: () -> Void)] = []
    
    var onAnimationComplete: (() -> Void)?
    
    init() {
        scene = SCNScene()
        cubeRoot = SCNNode()
        cubeRoot.name = "cubeRoot"
        // Default orientation: white up, green front, red right (standard)
        // Identity orientation with no rotation for correct opposite face pairing
        let baseRotation = simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))  // No rotation for standard orientation
        let tiltRight = simd_quatf(angle: Float.pi / 2, axis: simd_float3(0, 1, 0))      // Tilt right for visibility
        let tiltDown = simd_quatf(angle: -Float.pi / 12, axis: simd_float3(1, 0, 0))     // Small downward tilt
        cubeRoot.simdOrientation = tiltRight * tiltDown * baseRotation
        scene.rootNode.addChildNode(cubeRoot)
        
        setupCamera()
        setupLights()
        buildCubies()
        
        #if os(macOS)
        scene.background.contents = NSColor(white: 0.05, alpha: 1.0)
        #else
        scene.background.contents = UIColor(white: 0.05, alpha: 1.0)
        #endif
    }
    
    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 2.5)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLights() {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(2, 2, 2)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 400
        scene.rootNode.addChildNode(ambientLight)
    }
    
    private func buildCubies() {
        for x in -1...1 {
            for y in -1...1 {
                for z in -1...1 {
                    let cubie = makeCubie(x: x, y: y, z: z)
                    let position = SCNVector3(Float(x) * Float(cubieSize),
                                              Float(y) * Float(cubieSize),
                                              Float(z) * Float(cubieSize))
                    cubie.position = position
                    cubie.name = "cubie_\(x)_\(y)_\(z)"
                    cubies[cubie.name!] = cubie
                    cubeRoot.addChildNode(cubie)
                }
            }
        }
    }
    
    private func makeCubie(x: Int, y: Int, z: Int) -> SCNNode {
        let box = SCNBox(width: cubieSize, height: cubieSize, length: cubieSize, chamferRadius: 0.02)
        
        let faces: [(CubeFace?, Any)] = [
            (z == 1 ? .front : nil, faceColor(for: .front)),
            (x == 1 ? .right : nil, faceColor(for: .right)),
            (z == -1 ? .back : nil, faceColor(for: .back)),
            (x == -1 ? .left : nil, faceColor(for: .left)),
            (y == 1 ? .up : nil, faceColor(for: .up)),
            (y == -1 ? .down : nil, faceColor(for: .down))
        ]
        
        box.materials = faces.map { (face, color) in
            let material = SCNMaterial()
            material.diffuse.contents = face != nil ? color : interiorColor
            material.locksAmbientWithDiffuse = true
            return material
        }
        
        return SCNNode(geometry: box)
    }
    
    func animateMove(_ move: CubeMove, completion: @escaping () -> Void) {
        // Queue the animation
        animationQueue.append((move: move, completion: completion))
        
        // If not currently animating, start processing queue
        if !isAnimating {
            processNextAnimation()
        }
    }
    
    private func processNextAnimation() {
        guard !animationQueue.isEmpty else {
            isAnimating = false
            return
        }
        
        isAnimating = true
        let (move, completion) = animationQueue.removeFirst()
        
        let clockwise = move.direction != .counterClockwise
        let times = move.direction == .double ? 2 : 1
        
        let (affectedCubies, axis, baseAngle) = getAffectedCubiesAndAxis(for: move)
        let angle = baseAngle * Float(times) * (clockwise ? 1 : -1)
        
        let rotationNode = SCNNode()
        rotationNode.position = SCNVector3(0, 0, 0)
        cubeRoot.addChildNode(rotationNode)
        
        for cubie in affectedCubies {
            let worldPos = cubie.worldPosition
            cubie.removeFromParentNode()
            rotationNode.addChildNode(cubie)
            cubie.worldPosition = worldPos
        }
        
        let rotation = SCNAction.rotate(by: CGFloat(angle), around: axis, duration: 0.15)  // Fast animation
        rotation.timingMode = .linear  // Linear timing for instant effect
        
        rotationNode.runAction(rotation) { [weak self] in
            guard let self = self else { return }
            
            for cubie in affectedCubies {
                let worldPos = cubie.worldPosition
                let worldRot = cubie.worldOrientation
                cubie.removeFromParentNode()
                self.cubeRoot.addChildNode(cubie)
                cubie.worldPosition = worldPos
                cubie.worldOrientation = worldRot
                
                self.snapToGrid(cubie)
            }
            
            rotationNode.removeFromParentNode()
            self.updateCubieNames()
            
            // Call completion for this animation
            completion()
            
            // Process next animation in queue
            self.processNextAnimation()
        }
    }

    
    private func getAffectedCubiesAndAxis(for move: CubeMove) -> ([SCNNode], SCNVector3, Float) {
        let threshold: CGFloat = 0.1
        let size = cubieSize
        var result: [SCNNode] = []
        var axis = SCNVector3(0, 1, 0)
        var baseAngle: Float = -Float.pi / 2
        
        switch move.moveType {
        case .face(let face):
            for (_, cubie) in cubies {
                let pos = cubie.position
                let matches: Bool
                switch face {
                case .up: matches = CGFloat(pos.y) > size - threshold
                case .down: matches = CGFloat(pos.y) < -size + threshold
                case .left: matches = CGFloat(pos.x) < -size + threshold
                case .right: matches = CGFloat(pos.x) > size - threshold
                case .front: matches = CGFloat(pos.z) > size - threshold
                case .back: matches = CGFloat(pos.z) < -size + threshold
                }
                if matches { result.append(cubie) }
            }
            switch face {
            case .up: axis = SCNVector3(0, 1, 0); baseAngle = -Float.pi / 2
            case .down: axis = SCNVector3(0, 1, 0); baseAngle = Float.pi / 2
            case .left: axis = SCNVector3(1, 0, 0); baseAngle = Float.pi / 2
            case .right: axis = SCNVector3(1, 0, 0); baseAngle = -Float.pi / 2
            case .front: axis = SCNVector3(0, 0, 1); baseAngle = -Float.pi / 2
            case .back: axis = SCNVector3(0, 0, 1); baseAngle = Float.pi / 2
            }
            
        case .slice(let slice):
            for (_, cubie) in cubies {
                let pos = cubie.position
                let matches: Bool
                switch slice {
                case .middle: matches = abs(CGFloat(pos.x)) < threshold
                case .equator: matches = abs(CGFloat(pos.y)) < threshold
                case .standing: matches = abs(CGFloat(pos.z)) < threshold
                }
                if matches { result.append(cubie) }
            }
            switch slice {
            case .middle: axis = SCNVector3(1, 0, 0); baseAngle = Float.pi / 2  // follows L
            case .equator: axis = SCNVector3(0, 1, 0); baseAngle = Float.pi / 2  // follows D
            case .standing: axis = SCNVector3(0, 0, 1); baseAngle = -Float.pi / 2  // follows F
            }
            
        case .rotation(let rot):
            result = Array(cubies.values)
            switch rot {
            case .x: axis = SCNVector3(1, 0, 0); baseAngle = -Float.pi / 2  // follows R
            case .y: axis = SCNVector3(0, 1, 0); baseAngle = -Float.pi / 2  // follows U
            case .z: axis = SCNVector3(0, 0, 1); baseAngle = -Float.pi / 2  // follows F
            }
            
        case .wide(let wide):
            for (_, cubie) in cubies {
                let pos = cubie.position
                let matches: Bool
                switch wide {
                case .upWide: matches = CGFloat(pos.y) > -threshold
                case .downWide: matches = CGFloat(pos.y) < threshold
                case .leftWide: matches = CGFloat(pos.x) < threshold
                case .rightWide: matches = CGFloat(pos.x) > -threshold
                case .frontWide: matches = CGFloat(pos.z) > -threshold
                case .backWide: matches = CGFloat(pos.z) < threshold
                }
                if matches { result.append(cubie) }
            }
            switch wide {
            case .upWide: axis = SCNVector3(0, 1, 0); baseAngle = -Float.pi / 2
            case .downWide: axis = SCNVector3(0, 1, 0); baseAngle = Float.pi / 2
            case .leftWide: axis = SCNVector3(1, 0, 0); baseAngle = Float.pi / 2
            case .rightWide: axis = SCNVector3(1, 0, 0); baseAngle = -Float.pi / 2
            case .frontWide: axis = SCNVector3(0, 0, 1); baseAngle = -Float.pi / 2
            case .backWide: axis = SCNVector3(0, 0, 1); baseAngle = Float.pi / 2
            }
        }
        
        return (result, axis, baseAngle)
    }
    
    private func snapToGrid(_ cubie: SCNNode) {
        let gridSize = Float(cubieSize)
        cubie.position.x = CGFloat(round(Float(cubie.position.x) / gridSize) * gridSize)
        cubie.position.y = CGFloat(round(Float(cubie.position.y) / gridSize) * gridSize)
        cubie.position.z = CGFloat(round(Float(cubie.position.z) / gridSize) * gridSize)
        
        // Snap orientation to nearest 90-degree rotation to prevent drift
        snapOrientation(cubie)
    }
    
    private func snapOrientation(_ node: SCNNode) {
        // Convert quaternion to rotation matrix, then snap each axis to nearest 90°
        let q = node.simdOrientation
        
        // Convert to rotation matrix
        let rotMatrix = simd_float3x3(q)
        
        // Snap each column to the nearest axis-aligned unit vector
        let snappedX = snapToAxis(rotMatrix.columns.0)
        let snappedY = snapToAxis(rotMatrix.columns.1)
        let snappedZ = snapToAxis(rotMatrix.columns.2)
        
        // Reconstruct orthonormal matrix (ensure it's valid)
        let snappedMatrix = simd_float3x3(snappedX, snappedY, snappedZ)
        
        // Convert back to quaternion
        node.simdOrientation = simd_quatf(snappedMatrix)
    }
    
    private func snapToAxis(_ v: SIMD3<Float>) -> SIMD3<Float> {
        // Find which axis this vector is closest to
        let absX = abs(v.x)
        let absY = abs(v.y)
        let absZ = abs(v.z)
        
        if absX >= absY && absX >= absZ {
            return SIMD3<Float>(v.x > 0 ? 1 : -1, 0, 0)
        } else if absY >= absX && absY >= absZ {
            return SIMD3<Float>(0, v.y > 0 ? 1 : -1, 0)
        } else {
            return SIMD3<Float>(0, 0, v.z > 0 ? 1 : -1)
        }
    }
    
    private func updateCubieNames() {
        var newCubies: [String: SCNNode] = [:]
        let gridSize = Float(cubieSize)
        for (_, cubie) in cubies {
            let x = Int(round(Float(cubie.position.x) / gridSize))
            let y = Int(round(Float(cubie.position.y) / gridSize))
            let z = Int(round(Float(cubie.position.z) / gridSize))
            let name = "cubie_\(x)_\(y)_\(z)"
            cubie.name = name
            newCubies[name] = cubie
        }
        cubies = newCubies
    }
    
    var rootNode: SCNNode { cubeRoot }
    
    func setQuaternionOrientation(w: Float, x: Float, y: Float, z: Float) {
        // Apply quaternion directly to the cube root
        cubeRoot.simdOrientation = simd_quatf(ix: x, iy: y, iz: z, r: w)
    }
    
    func reset() {
        // Clear animation queue and reset flag
        animationQueue.removeAll()
        isAnimating = false
        
        for (_, cubie) in cubies {
            cubie.removeAllActions()
            cubie.removeFromParentNode()
        }
        cubies.removeAll()
        buildCubies()
        // Reset to default orientation: white up, green front, red right with slight left and upward tilt
        let baseRotation = simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))  // No rotation for standard orientation
        let tiltLeft = simd_quatf(angle: -Float.pi / 6, axis: simd_float3(0, 1, 0))      // Tilt left for visibility (clockwise around vertical)
        let tiltUp = simd_quatf(angle: Float.pi / 8, axis: simd_float3(1, 0, 0))         // Tilt upward for visibility (counter-clockwise around horizontal)
        cubeRoot.simdOrientation = tiltLeft * tiltUp * baseRotation
    }
    
    /// Update cube visuals to match the given state
    func syncState(_ state: CubeState) {
        // Clear animation queue and reset flag
        animationQueue.removeAll()
        isAnimating = false
        
        // Cancel any ongoing animations before rebuilding cubies
        for (_, cubie) in cubies {
            cubie.removeAllActions()
            cubie.removeFromParentNode()
        }
        cubies.removeAll()
        buildCubiesFromState(state)
    }
    
    private func buildCubiesFromState(_ state: CubeState) {
        for x in -1...1 {
            for y in -1...1 {
                for z in -1...1 {
                    let cubie = makeCubieFromState(x: x, y: y, z: z, state: state)
                    let position = SCNVector3(Float(x) * Float(cubieSize),
                                              Float(y) * Float(cubieSize),
                                              Float(z) * Float(cubieSize))
                    cubie.position = position
                    cubie.name = "cubie_\(x)_\(y)_\(z)"
                    cubies[cubie.name!] = cubie
                    cubeRoot.addChildNode(cubie)
                }
            }
        }
    }
    
    private func makeCubieFromState(x: Int, y: Int, z: Int, state: CubeState) -> SCNNode {
        let box = SCNBox(width: cubieSize, height: cubieSize, length: cubieSize, chamferRadius: 0.02)
        
        // Face order in state.facelets: U(0-8), D(9-17), L(18-26), R(27-35), F(36-44), B(45-53)
        // Map spatial directions to face indices
        let faces: [(CubeFace?, Int?)] = [
            (z == 1 ? .front : nil, z == 1 ? 4 : nil),  // Front face is index 4 (F)
            (x == 1 ? .right : nil, x == 1 ? 3 : nil),  // Right face is index 3 (R)
            (z == -1 ? .back : nil, z == -1 ? 5 : nil),  // Back face is index 5 (B)
            (x == -1 ? .left : nil, x == -1 ? 2 : nil),  // Left face is index 2 (L)
            (y == 1 ? .up : nil, y == 1 ? 0 : nil),     // Up face is index 0 (U)
            (y == -1 ? .down : nil, y == -1 ? 1 : nil)  // Down face is index 1 (D)
        ]
        
        // For each exposed face of this cubie, determine the facelet index based on position within the face
        let materials = faces.map { (face, faceIndex) -> SCNMaterial in
            let material = SCNMaterial()
            if let face = face, let faceIdx = faceIndex {
                // Calculate position within the 3x3 face grid based on cubie's xyz position
                let row: Int
                let col: Int
                
                switch face {
                case .up:    // Looking at U from above: x=-1 is left, z=1 is front (top row)
                    row = 1 - z  // z=1->0 (top), z=0->1 (middle), z=-1->2 (bottom)
                    col = x + 1  // x=-1->0 (left), x=0->1 (middle), x=1->2 (right)
                case .down:  // Looking at D from below: x=-1 is left, z=-1 is front (top row)
                    row = z + 1  // z=-1->0 (top), z=0->1 (middle), z=1->2 (bottom)
                    col = x + 1
                case .front: // Looking at F: x=-1 is left, y=1 is top
                    row = 1 - y  // y=1->0 (top), y=0->1 (middle), y=-1->2 (bottom)
                    col = x + 1  // x=-1->0 (left), x=0->1 (middle), x=1->2 (right)
                case .back:  // Looking at B: x=1 is left, y=1 is top
                    row = 1 - y  // y=1->0 (top), y=0->1 (middle), y=-1->2 (bottom)
                    col = 1 - x  // x=1->0 (left), x=0->1 (middle), x=-1->2 (right)
                case .left:  // Looking at L: z=1 is left, y=1 is top
                    row = 1 - y  // y=1->0 (top), y=0->1 (middle), y=-1->2 (bottom)
                    col = 1 - z  // z=1->0 (left), z=0->1 (middle), z=-1->2 (right)
                case .right: // Looking at R: z=-1 is left, y=1 is top
                    row = 1 - y  // y=1->0 (top), y=0->1 (middle), y=-1->2 (bottom)
                    col = z + 1  // z=-1->0 (left), z=0->1 (middle), z=1->2 (right)
                }
                
                let faceletIndex = faceIdx * 9 + row * 3 + col
                let color = state.facelets[faceletIndex]
                material.diffuse.contents = cubeColorToSceneColor(color)
            } else {
                material.diffuse.contents = interiorColor
            }
            material.locksAmbientWithDiffuse = true
            return material
        }
        
        box.materials = materials
        return SCNNode(geometry: box)
    }
    
    private func cubeColorToSceneColor(_ color: CubeColor) -> Any {
        #if os(macOS)
        switch color {
        case .white: return NSColor.white
        case .yellow: return NSColor.yellow
        case .orange: return NSColor.orange
        case .red: return NSColor.red
        case .green: return NSColor.systemGreen
        case .blue: return NSColor.systemBlue
        }
        #else
        switch color {
        case .white: return UIColor.white
        case .yellow: return UIColor.yellow
        case .orange: return UIColor.orange
        case .red: return UIColor.red
        case .green: return UIColor.green
        case .blue: return UIColor.blue
        }
        #endif
    }
    
    private func faceColor(for face: CubeFace) -> Any {
        // Standard orientation: U=White, D=Yellow, F=Green, B=Blue, L=Orange, R=Red
        #if os(macOS)
        switch face {
        case .up: return NSColor.white
        case .down: return NSColor.yellow
        case .left: return NSColor.orange
        case .right: return NSColor.red
        case .front: return NSColor.systemGreen
        case .back: return NSColor.systemBlue
        }
        #else
        switch face {
        case .up: return UIColor.white
        case .down: return UIColor.yellow
        case .left: return UIColor.orange
        case .right: return UIColor.red
        case .front: return UIColor.green
        case .back: return UIColor.blue
        }
        #endif
    }
    
    private var interiorColor: Any {
        #if os(macOS)
        return NSColor.black
        #else
        return UIColor.black
        #endif
    }
}

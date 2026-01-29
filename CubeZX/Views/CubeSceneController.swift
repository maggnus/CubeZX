import SceneKit
import Foundation

final class CubeSceneController {
    let scene: SCNScene
    private let cubeRoot: SCNNode
    private var cubies: [String: SCNNode] = [:]
    private let cubieSize: CGFloat = 0.3
    private var isAnimating = false
    
    var onAnimationComplete: (() -> Void)?
    
    init() {
        scene = SCNScene()
        cubeRoot = SCNNode()
        cubeRoot.name = "cubeRoot"
        cubeRoot.simdOrientation = simd_quatf(ix: 0.25, iy: -0.25, iz: 0.00, r: 0.94)
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
        guard !isAnimating else { return }
        isAnimating = true
        
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
        
        let rotation = SCNAction.rotate(by: CGFloat(angle), around: axis, duration: 0.2)
        rotation.timingMode = .easeInEaseOut
        
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
            self.isAnimating = false
            completion()
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
    
    func reset() {
        for (_, cubie) in cubies {
            cubie.removeFromParentNode()
        }
        cubies.removeAll()
        buildCubies()
        cubeRoot.simdOrientation = simd_quatf(ix: 0.25, iy: -0.25, iz: 0.00, r: 0.94)
    }
    
    private func faceColor(for face: CubeFace) -> Any {
        #if os(macOS)
        switch face {
        case .up: return NSColor.yellow
        case .down: return NSColor.white
        case .left: return NSColor.orange
        case .right: return NSColor.red
        case .front: return NSColor.systemBlue
        case .back: return NSColor.systemGreen
        }
        #else
        switch face {
        case .up: return UIColor.yellow
        case .down: return UIColor.white
        case .left: return UIColor.orange
        case .right: return UIColor.red
        case .front: return UIColor.blue
        case .back: return UIColor.green
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

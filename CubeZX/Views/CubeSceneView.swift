import SceneKit
import SwiftUI

struct CubeSceneView: View {
    let cubeState: CubeState
    let pendingMove: CubeMove?
    let shouldReset: Bool
    let onMoveAnimated: () -> Void
    let onResetComplete: () -> Void
    let onOrientationChanged: ((Float, Float, Float, Float) -> Void)?

    var body: some View {
        CubeSceneRepresentable(cubeState: cubeState, pendingMove: pendingMove, shouldReset: shouldReset, onMoveAnimated: onMoveAnimated, onResetComplete: onResetComplete, onOrientationChanged: onOrientationChanged)
            .cornerRadius(12)
    }
}

#if os(macOS)
private struct CubeSceneRepresentable: NSViewRepresentable {
    let cubeState: CubeState
    let pendingMove: CubeMove?
    let shouldReset: Bool
    let onMoveAnimated: () -> Void
    let onResetComplete: () -> Void
    let onOrientationChanged: ((Float, Float, Float, Float) -> Void)?

    func makeNSView(context: Context) -> RotatableSCNView {
        let controller = CubeSceneController()
        let scnView = RotatableSCNView()
        scnView.scene = controller.scene
        scnView.sceneController = controller
        scnView.onOrientationChanged = onOrientationChanged
        scnView.backgroundColor = NSColor(red: 0.04, green: 0.04, blue: 0.10, alpha: 1.0)
        scnView.antialiasingMode = .multisampling4X
        return scnView
    }

    func updateNSView(_ scnView: RotatableSCNView, context: Context) {
        guard let controller = scnView.sceneController else { return }
        
        if shouldReset {
            controller.reset()
            DispatchQueue.main.async {
                onResetComplete()
            }
        } else if let move = pendingMove {
            controller.animateMove(move) {
                DispatchQueue.main.async {
                    onMoveAnimated()
                }
            }
        }
    }
}

final class RotatableSCNView: SCNView {
    var sceneController: CubeSceneController?
    var onOrientationChanged: ((Float, Float, Float, Float) -> Void)?
    private var lastMouseLocation: CGPoint = .zero

    override func mouseDown(with event: NSEvent) {
        lastMouseLocation = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let deltaX = Float(location.x - lastMouseLocation.x) * 0.01
        let deltaY = Float(location.y - lastMouseLocation.y) * 0.01
        lastMouseLocation = location

        guard let cubeRoot = sceneController?.rootNode else { return }
        
        let rotationX = simd_quatf(angle: -deltaY, axis: simd_float3(1, 0, 0))
        let rotationY = simd_quatf(angle: deltaX, axis: simd_float3(0, 1, 0))
        
        let currentOrientation = cubeRoot.simdOrientation
        cubeRoot.simdOrientation = rotationY * rotationX * currentOrientation
        
        let q = cubeRoot.simdOrientation
        onOrientationChanged?(q.imag.x, q.imag.y, q.imag.z, q.real)
    }
}
#else
private struct CubeSceneRepresentable: UIViewRepresentable {
    let cubeState: CubeState
    let pendingMove: CubeMove?
    let shouldReset: Bool
    let onMoveAnimated: () -> Void
    let onResetComplete: () -> Void
    let onOrientationChanged: ((Float, Float, Float, Float) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let controller = CubeSceneController()
        let scnView = SCNView()
        scnView.scene = controller.scene
        scnView.allowsCameraControl = true
        scnView.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        scnView.antialiasingMode = .multisampling4X
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
    }
}
#endif

extension CubeSceneView {

    fileprivate static func makeScene(cubeState: CubeState) -> SCNScene {
        let scene = SCNScene()
        let cubeRoot = SCNNode()
        let cubieSize: CGFloat = 0.3
        let spacing: Float = 0.0

        for x in -1...1 {
            for y in -1...1 {
                for z in -1...1 {
                    let cubie = makeCubie(x: x, y: y, z: z, size: cubieSize, cubeState: cubeState)
                    let position = SCNVector3(Float(x) * Float(cubieSize) + Float(x) * spacing,
                                              Float(y) * Float(cubieSize) + Float(y) * spacing,
                                              Float(z) * Float(cubieSize) + Float(z) * spacing)
                    cubie.position = position
                    cubeRoot.addChildNode(cubie)
                }
            }
        }

        cubeRoot.name = "cubeRoot"
        cubeRoot.eulerAngles = SCNVector3(Float.pi / 6, Float.pi / 5, 0)
        scene.rootNode.addChildNode(cubeRoot)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 2.5)
        scene.rootNode.addChildNode(cameraNode)

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

        scene.background.contents = backgroundClearColor

        return scene
    }

    private static var backgroundClearColor: Any {
#if canImport(UIKit)
        return UIColor(white: 0.05, alpha: 1.0)
#else
        return NSColor(white: 0.05, alpha: 1.0)
#endif
    }

    private static func makeCubie(x: Int, y: Int, z: Int, size: CGFloat, cubeState: CubeState) -> SCNNode {
        let box = SCNBox(width: size, height: size, length: size, chamferRadius: 0.02)
        
        let faceData: [(CubeFace?, Int, Int)] = [
            (z == 1 ? .front : nil, x + 1, 1 - y),
            (x == 1 ? .right : nil, 1 - z, 1 - y),
            (z == -1 ? .back : nil, 1 - x, 1 - y),
            (x == -1 ? .left : nil, z + 1, 1 - y),
            (y == 1 ? .up : nil, x + 1, z + 1),
            (y == -1 ? .down : nil, x + 1, 1 - z)
        ]
        
        box.materials = faceData.map { (face, col, row) in
            let material = SCNMaterial()
            if let face = face {
                let faceletIndex = faceletIndex(face: face, row: row, col: col)
                let cubeColor = cubeState.facelets[faceletIndex]
                material.diffuse.contents = color(for: cubeColor)
            } else {
                material.diffuse.contents = cubeInteriorColor
            }
            material.locksAmbientWithDiffuse = true
            return material
        }
        return SCNNode(geometry: box)
    }
    
    private static func faceletIndex(face: CubeFace, row: Int, col: Int) -> Int {
        let faceOffset: Int
        switch face {
        case .up: faceOffset = 0
        case .down: faceOffset = 9
        case .left: faceOffset = 18
        case .right: faceOffset = 27
        case .front: faceOffset = 36
        case .back: faceOffset = 45
        }
        return faceOffset + row * 3 + col
    }

    private static var cubeInteriorColor: Any {
#if canImport(UIKit)
        return UIColor.black
#else
        return NSColor.black
#endif
    }

    private static func color(for cubeColor: CubeColor) -> Any {
#if canImport(UIKit)
        switch cubeColor {
        case .white: return UIColor.white
        case .yellow: return UIColor.yellow
        case .orange: return UIColor.orange
        case .red: return UIColor.red
        case .green: return UIColor.green
        case .blue: return UIColor.blue
        }
#else
        switch cubeColor {
        case .white: return NSColor.white
        case .yellow: return NSColor.yellow
        case .orange: return NSColor.orange
        case .red: return NSColor.red
        case .green: return NSColor.systemGreen
        case .blue: return NSColor.systemBlue
        }
#endif
    }

    private static func color(for face: CubeFace) -> Any {
#if canImport(UIKit)
        switch face {
        case .up: return UIColor.white
        case .down: return UIColor.yellow
        case .left: return UIColor.orange
        case .right: return UIColor.red
        case .front: return UIColor.green
        case .back: return UIColor.blue
        }
#else
        switch face {
        case .up: return NSColor.white
        case .down: return NSColor.yellow
        case .left: return NSColor.orange
        case .right: return NSColor.red
        case .front: return NSColor.systemGreen
        case .back: return NSColor.systemBlue
        }
#endif
    }
}

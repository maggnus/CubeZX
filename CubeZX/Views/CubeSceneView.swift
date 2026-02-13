import SceneKit
import SwiftUI

struct CubeSceneView: View {
    let cubeState: CubeState
    let pendingMove: CubeMove?
    let shouldReset: Bool
    let shouldSyncState: Bool
    let quatW: Float
    let quatX: Float
    let quatY: Float
    let quatZ: Float
    let onMoveAnimated: () -> Void
    let onResetComplete: () -> Void
    let onStateSyncComplete: () -> Void
    let onUserInteraction: (() -> Void)?
    let onDragUpdate: ((Float, Float, Float, Float) -> Void)?  // Called during drag
    let onDragEnd: (() -> Void)?  // Called when drag ends

    var body: some View {
        CubeSceneRepresentable(cubeState: cubeState, pendingMove: pendingMove, shouldReset: shouldReset, shouldSyncState: shouldSyncState, quatW: quatW, quatX: quatX, quatY: quatY, quatZ: quatZ, onMoveAnimated: onMoveAnimated, onResetComplete: onResetComplete, onStateSyncComplete: onStateSyncComplete, onUserInteraction: onUserInteraction, onDragUpdate: onDragUpdate, onDragEnd: onDragEnd)
            .cornerRadius(12)
    }
}

#if os(macOS)
private struct CubeSceneRepresentable: NSViewRepresentable {
    let cubeState: CubeState
    let pendingMove: CubeMove?
    let shouldReset: Bool
    let shouldSyncState: Bool
    let quatW: Float
    let quatX: Float
    let quatY: Float
    let quatZ: Float
    let onMoveAnimated: () -> Void
    let onResetComplete: () -> Void
    let onStateSyncComplete: () -> Void
    let onUserInteraction: (() -> Void)?
    let onDragUpdate: ((Float, Float, Float, Float) -> Void)?
    let onDragEnd: (() -> Void)?

    func makeNSView(context: Context) -> RotatableSCNView {
        let controller = CubeSceneController()
        let scnView = RotatableSCNView()
        scnView.scene = controller.scene
        scnView.sceneController = controller
        scnView.onUserInteraction = onUserInteraction
        scnView.onDragUpdate = onDragUpdate
        scnView.onDragEnd = onDragEnd
        scnView.backgroundColor = NSColor(red: 0.04, green: 0.04, blue: 0.10, alpha: 1.0)
        scnView.antialiasingMode = .multisampling4X
        return scnView
    }

    func updateNSView(_ scnView: RotatableSCNView, context: Context) {
        guard let controller = scnView.sceneController else { return }

        if shouldSyncState {
            scnView.lastAnimatedMoveId = nil  // Clear tracking on sync
            controller.syncState(cubeState)
            DispatchQueue.main.async {
                onStateSyncComplete()
            }
        } else if shouldReset {
            scnView.lastAnimatedMoveId = nil  // Clear tracking on reset
            controller.reset()
            DispatchQueue.main.async {
                onResetComplete()
            }
        } else if let move = pendingMove, !shouldSyncState {
            // Only queue animation if this is a NEW move (check by unique ID)
            if scnView.lastAnimatedMoveId != move.id {
                scnView.lastAnimatedMoveId = move.id
                controller.animateMove(move) {
                    DispatchQueue.main.async {
                        onMoveAnimated()
                    }
                }
            }
        }

        // Always apply quaternion orientation
        controller.setQuaternionOrientation(w: quatW, x: quatX, y: quatY, z: quatZ)
    }
}

final class RotatableSCNView: SCNView {
    var sceneController: CubeSceneController?
    var onUserInteraction: (() -> Void)?
    var onDragUpdate: ((Float, Float, Float, Float) -> Void)?  // Called during drag with current orientation
    var onDragEnd: (() -> Void)?  // Called when drag ends
    private var lastMouseLocation: CGPoint = .zero
    var lastAnimatedMoveId: UUID?  // Track last move ID to prevent duplicate animations

    override func mouseDown(with event: NSEvent) {
        lastMouseLocation = convert(event.locationInWindow, from: nil)
        onUserInteraction?()  // Start dragging
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let deltaX = Float(location.x - lastMouseLocation.x) * 0.01
        let deltaY = Float(location.y - lastMouseLocation.y) * 0.01
        lastMouseLocation = location

        guard let cubeRoot = sceneController?.rootNode else { return }
        
        // After reset: white up, red front, blue right
        // Both rotations in WORLD space for intuitive screen-relative control
        // Horizontal mouse (deltaX) -> rotate around World Y axis (turn left/right)
        // Vertical mouse (deltaY) -> rotate around World X axis (tilt up/down)
        let currentOrientation = cubeRoot.simdOrientation
        let rotationY = simd_quatf(angle: deltaX, axis: simd_float3(0, 1, 0))
        let rotationX = simd_quatf(angle: -deltaY, axis: simd_float3(1, 0, 0))
        
        // Apply both rotations in world space (left of currentOrientation)
        cubeRoot.simdOrientation = rotationX * rotationY * currentOrientation
        
        // Update offset continuously during drag
        let q = cubeRoot.simdOrientation
        onDragUpdate?(q.imag.x, q.imag.y, q.imag.z, q.real)
    }
    
    override func mouseUp(with event: NSEvent) {
        onDragEnd?()  // Drag finished
    }
}
#else
private struct CubeSceneRepresentable: UIViewRepresentable {
    let cubeState: CubeState
    let pendingMove: CubeMove?
    let shouldReset: Bool
    let quatW: Float
    let quatX: Float
    let quatY: Float
    let quatZ: Float
    let onMoveAnimated: () -> Void
    let onResetComplete: () -> Void
    let onUserInteraction: (() -> Void)?
    let onDragUpdate: ((Float, Float, Float, Float) -> Void)?
    let onDragEnd: (() -> Void)?

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


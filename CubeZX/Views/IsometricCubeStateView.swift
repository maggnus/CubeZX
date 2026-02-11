
import SwiftUI

/// Isometric renderer for CubeState: draws Up, Right, Front faces only.
struct IsometricCubeStateView: View {
    let state: CubeState

    init(state: CubeState) {
        self.state = state
    }

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let s = min(size.width, size.height)
                let cx = size.width / 2
                let cy = size.height / 2 + s * 0.04
                let unit = s * 0.12

                let iso: (CGFloat, CGFloat, CGFloat) -> CGPoint = { x, y, z in
                    CGPoint(
                        x: cx + (x - z) * 0.866 * unit,
                        y: cy - y * unit + (x + z) * 0.5 * unit
                    )
                }

                // Up face (U, indices 0..8)
                // 3D logic: row = z + 1 (z=1 front->row=2, z=-1 back->row=0), col = x + 1
                for z in (-1...1) {
                    for x in (-1...1) {
                        let row = z + 1
                        let col = x + 1
                        let faceletIndex = 0 * 9 + row * 3 + col
                        let tl = iso(CGFloat(x) - 0.45, 1.5, CGFloat(z) - 0.45)
                        let tr = iso(CGFloat(x) + 0.45, 1.5, CGFloat(z) - 0.45)
                        let bl = iso(CGFloat(x) - 0.45, 1.5, CGFloat(z) + 0.45)
                        let br = iso(CGFloat(x) + 0.45, 1.5, CGFloat(z) + 0.45)

                        var path = Path()
                        path.move(to: tl)
                        path.addLine(to: tr)
                        path.addLine(to: br)
                        path.addLine(to: bl)
                        path.closeSubpath()

                        let color = colorForFacelet(state.facelets[faceletIndex])
                        context.fill(path, with: .color(color))
                        context.stroke(path, with: .color(.black.opacity(0.6)), lineWidth: 0.5)
                    }
                }

                // Right face (R, indices 27..35)
                // 3D logic: row = 1 - y, col = 1 - z (z=1 front->col=0, z=-1 back->col=2)
                for y in (-1...1) {
                    for z in (-1...1) {
                        let row = 1 - y
                        let col = 1 - z
                        let faceletIndex = 3 * 9 + row * 3 + col
                        let x: CGFloat = 1.5
                        let tl = iso(x, CGFloat(y) + 0.45, CGFloat(z) - 0.45)
                        let tr = iso(x, CGFloat(y) + 0.45, CGFloat(z) + 0.45)
                        let bl = iso(x, CGFloat(y) - 0.45, CGFloat(z) - 0.45)
                        let br = iso(x, CGFloat(y) - 0.45, CGFloat(z) + 0.45)

                        var path = Path()
                        path.move(to: tl)
                        path.addLine(to: tr)
                        path.addLine(to: br)
                        path.addLine(to: bl)
                        path.closeSubpath()

                        let color = colorForFacelet(state.facelets[faceletIndex])
                        context.fill(path, with: .color(color))
                        context.stroke(path, with: .color(.black.opacity(0.6)), lineWidth: 0.5)
                    }
                }

                // Front face (F, indices 36..44)
                // 3D logic: row = 1 - y, col = x + 1
                for y in (-1...1) {
                    for x in (-1...1) {
                        let row = 1 - y
                        let col = x + 1
                        let faceletIndex = 4 * 9 + row * 3 + col
                        let z: CGFloat = 1.5
                        let tl = iso(CGFloat(x) - 0.45, CGFloat(y) + 0.45, z)
                        let tr = iso(CGFloat(x) + 0.45, CGFloat(y) + 0.45, z)
                        let bl = iso(CGFloat(x) - 0.45, CGFloat(y) - 0.45, z)
                        let br = iso(CGFloat(x) + 0.45, CGFloat(y) - 0.45, z)

                        var path = Path()
                        path.move(to: tl)
                        path.addLine(to: tr)
                        path.addLine(to: br)
                        path.addLine(to: bl)
                        path.closeSubpath()

                        let color = colorForFacelet(state.facelets[faceletIndex])
                        context.fill(path, with: .color(color))
                        context.stroke(path, with: .color(.black.opacity(0.6)), lineWidth: 0.5)
                    }
                }
            }
        }
    }

    private func colorForFacelet(_ f: CubeColor) -> Color {
        switch f {
        case .white: return .white
        case .yellow: return .yellow
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        }
    }
}

#if DEBUG
struct IsometricCubeStateView_Previews: PreviewProvider {
    static var previews: some View {
        let cs = CubeState.solved()
        IsometricCubeStateView(state: cs)
            .frame(width: 220, height: 220)
            .padding()
    }
}
#endif
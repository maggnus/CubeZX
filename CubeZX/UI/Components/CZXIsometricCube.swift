//
//  CZXIsometricCube.swift
//  CubeZX
//
//  Isometric cube view with theme support
//

import SwiftUI

/// Isometric renderer for CubeState with theme support
struct CZXIsometricCube: View {
    @Environment(\.theme) private var theme
    let state: CubeState
    let size: CGFloat
    
    init(state: CubeState, size: CGFloat = 100) {
        self.state = state
        self.size = size
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let cx = canvasSize.width / 2
            let cy = canvasSize.height / 2 + s * 0.04
            let unit = s * 0.12
            
            let iso: (CGFloat, CGFloat, CGFloat) -> CGPoint = { x, y, z in
                CGPoint(
                    x: cx + (x - z) * 0.866 * unit,
                    y: cy - y * unit + (x + z) * 0.5 * unit
                )
            }
            
            // Up face (U, indices 0..8)
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
        .frame(width: size, height: size)
    }
    
    private func colorForFacelet(_ f: CubeColor) -> Color {
        switch f {
        case .white: return theme.colors.cube.white
        case .yellow: return theme.colors.cube.yellow
        case .blue: return theme.colors.cube.blue
        case .green: return theme.colors.cube.green
        case .orange: return theme.colors.cube.orange
        case .red: return theme.colors.cube.red
        }
    }
}

// MARK: - Theme Extension for Cube Colors

extension Theme.Colors {
    struct CubeColors {
        let white: Color
        let yellow: Color
        let blue: Color
        let green: Color
        let orange: Color
        let red: Color
        
        static let `default` = CubeColors(
            white: Color(hex: "#F5F5F5"),
            yellow: Color(hex: "#FFD500"),
            blue: Color(hex: "#0051BA"),
            green: Color(hex: "#009E60"),
            orange: Color(hex: "#FF5800"),
            red: Color(hex: "#C41E3A")
        )
    }
    
    var cube: CubeColors { .default }
}

// MARK: - Preview

#Preview("CZXIsometricCube") {
    ZStack {
        Theme.shared.colors.background.primary
            .ignoresSafeArea()
        
        CZXIsometricCube(state: CubeState.solved(), size: 150)
    }
    .environment(Theme.shared)
}

import SwiftUI

struct NotationPopupLegacy: View {
    let onClose: () -> Void
    let onSelect: ((CubeState) -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Notation")
                    .font(.headline)
                Spacer()
                Text("Shift = '")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 4) {
                        NotationCubePreview(notation: "R", onSelect: onSelect)
                        NotationCubePreview(notation: "L", onSelect: onSelect)
                        NotationCubePreview(notation: "U", onSelect: onSelect)
                        NotationCubePreview(notation: "D", onSelect: onSelect)
                        NotationCubePreview(notation: "F", onSelect: onSelect)
                        NotationCubePreview(notation: "B", onSelect: onSelect)
                        
                        NotationCubePreview(notation: "R'", onSelect: onSelect)
                        NotationCubePreview(notation: "L'", onSelect: onSelect)
                        NotationCubePreview(notation: "U'", onSelect: onSelect)
                        NotationCubePreview(notation: "D'", onSelect: onSelect)
                        NotationCubePreview(notation: "F'", onSelect: onSelect)
                        NotationCubePreview(notation: "B'", onSelect: onSelect)
                        
                        NotationCubePreview(notation: "M", onSelect: onSelect)
                        NotationCubePreview(notation: "E", onSelect: onSelect)
                        NotationCubePreview(notation: "S", onSelect: onSelect)
                        NotationCubePreview(notation: "x", onSelect: onSelect)
                        NotationCubePreview(notation: "y", onSelect: onSelect)
                        NotationCubePreview(notation: "z", onSelect: onSelect)
                        
                        NotationCubePreview(notation: "M'", onSelect: onSelect)
                        NotationCubePreview(notation: "E'", onSelect: onSelect)
                        NotationCubePreview(notation: "S'", onSelect: onSelect)
                        NotationCubePreview(notation: "x'", onSelect: onSelect)
                        NotationCubePreview(notation: "y'", onSelect: onSelect)
                        NotationCubePreview(notation: "z'", onSelect: onSelect)
                        
                        NotationCubePreview(notation: "r", onSelect: onSelect)
                        NotationCubePreview(notation: "l", onSelect: onSelect)
                        NotationCubePreview(notation: "u", onSelect: onSelect)
                        NotationCubePreview(notation: "d", onSelect: onSelect)
                        NotationCubePreview(notation: "f", onSelect: onSelect)
                        NotationCubePreview(notation: "b", onSelect: onSelect)
                        
                        NotationCubePreview(notation: "r'", onSelect: onSelect)
                        NotationCubePreview(notation: "l'", onSelect: onSelect)
                        NotationCubePreview(notation: "u'", onSelect: onSelect)
                        NotationCubePreview(notation: "d'", onSelect: onSelect)
                        NotationCubePreview(notation: "f'", onSelect: onSelect)
                        NotationCubePreview(notation: "b'", onSelect: onSelect)
                    }
                }
            }
            
        }
        .padding(16)
        .background(Color.black.opacity(0.85))
        .cornerRadius(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct NotationCubePreview: View {
    let notation: String
    let onSelect: ((CubeState) -> Void)?

    var body: some View {
        Button(action: { select() }) {
            VStack(spacing: 4) {
                IsometricCubeStateView(state: createStateFromNotation())
                    .frame(width: 90, height: 90)
                Text(notation)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
        }
        .buttonStyle(.plain)
    }

    private func select() {
        let state = createStateFromNotation()
        onSelect?(state)
    }

    private func createStateFromNotation() -> CubeState {
        var state = CubeState.solved()
        if let move = parseMove(notation) {
            state.apply(move)
        }
        return state
    }

    private func parseMove(_ notation: String) -> CubeMove? {
        guard !notation.isEmpty else { return nil }

        let isPrime = notation.contains("'")
        let isDouble = notation.contains("2")
        let direction: CubeMoveDirection = isDouble ? .double : (isPrime ? .counterClockwise : .clockwise)

        let base = notation.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "2", with: "")

        switch base {
        case "R": return CubeMove(face: .right, direction: direction)
        case "L": return CubeMove(face: .left, direction: direction)
        case "U": return CubeMove(face: .up, direction: direction)
        case "D": return CubeMove(face: .down, direction: direction)
        case "F": return CubeMove(face: .front, direction: direction)
        case "B": return CubeMove(face: .back, direction: direction)
        case "M": return CubeMove(slice: .middle, direction: direction)
        case "E": return CubeMove(slice: .equator, direction: direction)
        case "S": return CubeMove(slice: .standing, direction: direction)
        case "X", "x": return CubeMove(rotation: .x, direction: direction)
        case "Y", "y": return CubeMove(rotation: .y, direction: direction)
        case "Z", "z": return CubeMove(rotation: .z, direction: direction)
        case "r": return CubeMove(wide: .rightWide, direction: direction)
        case "l": return CubeMove(wide: .leftWide, direction: direction)
        case "u": return CubeMove(wide: .upWide, direction: direction)
        case "d": return CubeMove(wide: .downWide, direction: direction)
        case "f": return CubeMove(wide: .frontWide, direction: direction)
        case "b": return CubeMove(wide: .backWide, direction: direction)
        default: return nil
        }
    }
}

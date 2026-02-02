import SwiftUI

struct NotationPopup: View {
    let onClose: () -> Void
    
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
                        NotationCubePreview(notation: "R")
                        NotationCubePreview(notation: "L")
                        NotationCubePreview(notation: "U")
                        NotationCubePreview(notation: "D")
                        NotationCubePreview(notation: "F")
                        NotationCubePreview(notation: "B")
                        
                        NotationCubePreview(notation: "R'")
                        NotationCubePreview(notation: "L'")
                        NotationCubePreview(notation: "U'")
                        NotationCubePreview(notation: "D'")
                        NotationCubePreview(notation: "F'")
                        NotationCubePreview(notation: "B'")
                        
                        NotationCubePreview(notation: "M")
                        NotationCubePreview(notation: "E")
                        NotationCubePreview(notation: "S")
                        NotationCubePreview(notation: "x")
                        NotationCubePreview(notation: "y")
                        NotationCubePreview(notation: "z")
                        
                        NotationCubePreview(notation: "M'")
                        NotationCubePreview(notation: "E'")
                        NotationCubePreview(notation: "S'")
                        NotationCubePreview(notation: "x'")
                        NotationCubePreview(notation: "y'")
                        NotationCubePreview(notation: "z'")
                        
                        NotationCubePreview(notation: "r")
                        NotationCubePreview(notation: "l")
                        NotationCubePreview(notation: "u")
                        NotationCubePreview(notation: "d")
                        NotationCubePreview(notation: "f")
                        NotationCubePreview(notation: "b")
                        
                        NotationCubePreview(notation: "r'")
                        NotationCubePreview(notation: "l'")
                        NotationCubePreview(notation: "u'")
                        NotationCubePreview(notation: "d'")
                        NotationCubePreview(notation: "f'")
                        NotationCubePreview(notation: "b'")
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
    
    var body: some View {
        VStack(spacing: 4) {
            IsometricCubeStateView(scramble: notation)
                .frame(width: 90, height: 90)
            Text(notation)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
        }
    }
}

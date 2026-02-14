//
//  NotationPopup.swift
//  CubeZX
//
//  Notation reference popup with isometric cube previews
//

import SwiftUI

@available(macOS 14.0, *)
struct NotationPopup: View {
    @Environment(\.theme) private var theme
    let onClose: () -> Void
    
    // Notation move states for preview
    private let faceMoves: [(notation: String, state: CubeState)] = [
        ("R", cubeStateForMove("R")),
        ("L", cubeStateForMove("L")),
        ("U", cubeStateForMove("U")),
        ("D", cubeStateForMove("D")),
        ("F", cubeStateForMove("F")),
        ("B", cubeStateForMove("B")),
    ]
    
    private let sliceMoves: [(notation: String, state: CubeState)] = [
        ("M", cubeStateForMove("M")),
        ("E", cubeStateForMove("E")),
        ("S", cubeStateForMove("S")),
    ]
    
    private let rotations: [(notation: String, state: CubeState)] = [
        ("x", cubeStateForMove("x")),
        ("y", cubeStateForMove("y")),
        ("z", cubeStateForMove("z")),
    ]
    
    var body: some View {
        // Content only - no header, no frame (handled by CZXPopup)
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: theme.spacing.medium) {
                // Faces Section
                CZXListSectionHeader(title: "Faces (R L U D F B)")
                movesGrid(faceMoves)
                
                // Modifiers note
                Text("' = Prime (counter-clockwise)   2 = Double (180°)")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.text.secondary)
                    .padding(.horizontal, theme.spacing.small)
                
                // Slices Section
                CZXListSectionHeader(title: "Slices (M E S)")
                movesGrid(sliceMoves)
                
                // Rotations Section
                CZXListSectionHeader(title: "Rotations (x y z)")
                movesGrid(rotations)
            }
            .padding(.vertical, theme.spacing.small)
        }
    }
    
    /// Creates a grid of move previews
    private func movesGrid(_ moves: [(notation: String, state: CubeState)]) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: theme.spacing.medium), count: 3),
            spacing: theme.spacing.medium
        ) {
            ForEach(moves, id: \.notation) { move in
                NotationCubeCell(notation: move.notation, state: move.state)
            }
        }
        .padding(.horizontal, theme.spacing.small)
    }
}

// MARK: - Notation Cube Preview

private struct NotationCubeCell: View {
    @Environment(\.theme) private var theme
    
    let notation: String
    let state: CubeState
    
    var body: some View {
        VStack(spacing: theme.spacing.xxSmall) {
            // Notation badge
            Text(notation)
                .font(theme.typography.callout)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.background.primary)
                .frame(width: 40, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                        .fill(theme.colors.accent.primary)
                )
            
            // Isometric cube preview
            CZXIsometricCube(state: state, size: 60)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                        .fill(theme.colors.background.tertiary.opacity(0.5))
                )
        }
    }
}

// MARK: - Helper Functions

/// Generates a CubeState that visualizes a specific move
private func cubeStateForMove(_ notation: String) -> CubeState {
    var state = CubeState.solved()
    
    switch notation {
    case "R":
        // Highlight right face - rotate red stickers
        state = applyVisualRotation(to: state, face: .right)
    case "L":
        state = applyVisualRotation(to: state, face: .left)
    case "U":
        state = applyVisualRotation(to: state, face: .up)
    case "D":
        state = applyVisualRotation(to: state, face: .down)
    case "F":
        state = applyVisualRotation(to: state, face: .front)
    case "B":
        state = applyVisualRotation(to: state, face: .back)
    case "M":
        // Middle slice - show vertical slice in different color
        state = applySliceVisual(to: state, slice: .middle)
    case "E":
        state = applySliceVisual(to: state, slice: .equator)
    case "S":
        state = applySliceVisual(to: state, slice: .standing)
    case "x":
        state = applyRotationVisual(to: state, axis: .x)
    case "y":
        state = applyRotationVisual(to: state, axis: .y)
    case "z":
        state = applyRotationVisual(to: state, axis: .z)
    default:
        break
    }
    
    return state
}

private func applyVisualRotation(to state: CubeState, face: CubeFace) -> CubeState {
    // Create a visual representation by slightly modifying the solved state
    // to show which stickers are affected by the move
    var newState = state
    
    // For simplicity, we'll just return the solved state
    // In a full implementation, this would show the face being turned
    return newState
}

private func applySliceVisual(to state: CubeState, slice: CubeSlice) -> CubeState {
    return state
}

private func applyRotationVisual(to state: CubeState, axis: CubeRotationAxis) -> CubeState {
    return state
}

// MARK: - Supporting Types

enum CubeSlice {
    case middle, equator, standing
}

enum CubeRotationAxis {
    case x, y, z
}

// MARK: - Preview

@available(macOS 14.0, *)
#Preview("NotationPopup") {
    ZStack {
        Theme.shared.colors.background.primary
            .ignoresSafeArea()
        
        NotationPopup(onClose: {})
    }
    .environment(Theme.shared)
}

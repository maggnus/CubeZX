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
    
    // Face moves with all variants (clockwise, prime, double)
    private let faceMoves: [(notation: String, state: CubeState)] = [
        ("R", cubeStateForMove("R")),
        ("R'", cubeStateForMove("R'")),
        ("R2", cubeStateForMove("R2")),
        ("L", cubeStateForMove("L")),
        ("L'", cubeStateForMove("L'")),
        ("L2", cubeStateForMove("L2")),
        ("U", cubeStateForMove("U")),
        ("U'", cubeStateForMove("U'")),
        ("U2", cubeStateForMove("U2")),
        ("D", cubeStateForMove("D")),
        ("D'", cubeStateForMove("D'")),
        ("D2", cubeStateForMove("D2")),
        ("F", cubeStateForMove("F")),
        ("F'", cubeStateForMove("F'")),
        ("F2", cubeStateForMove("F2")),
        ("B", cubeStateForMove("B")),
        ("B'", cubeStateForMove("B'")),
        ("B2", cubeStateForMove("B2")),
    ]
    
    // Slice moves
    private let sliceMoves: [(notation: String, state: CubeState)] = [
        ("M", cubeStateForMove("M")),
        ("M'", cubeStateForMove("M'")),
        ("M2", cubeStateForMove("M2")),
        ("E", cubeStateForMove("E")),
        ("E'", cubeStateForMove("E'")),
        ("E2", cubeStateForMove("E2")),
        ("S", cubeStateForMove("S")),
        ("S'", cubeStateForMove("S'")),
        ("S2", cubeStateForMove("S2")),
    ]
    
    // Rotations
    private let rotations: [(notation: String, state: CubeState)] = [
        ("x", cubeStateForMove("x")),
        ("x'", cubeStateForMove("x'")),
        ("x2", cubeStateForMove("x2")),
        ("y", cubeStateForMove("y")),
        ("y'", cubeStateForMove("y'")),
        ("y2", cubeStateForMove("y2")),
        ("z", cubeStateForMove("z")),
        ("z'", cubeStateForMove("z'")),
        ("z2", cubeStateForMove("z2")),
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
    
    /// Creates a dynamic grid of move previews
    private func movesGrid(_ moves: [(notation: String, state: CubeState)]) -> some View {
        let columns = [
            GridItem(.adaptive(minimum: 70, maximum: 80), spacing: theme.spacing.small)
        ]
        
        return LazyVGrid(columns: columns, spacing: theme.spacing.small) {
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
            // Isometric cube preview - no background
            CZXIsometricCube(state: state, size: 55)
            
            // Notation label at bottom - smaller, no background
            Text(notation)
                .font(theme.typography.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.text.secondary)
        }
    }
}

// MARK: - Helper Functions

/// Generates a CubeState that visualizes a specific move by applying it
private func cubeStateForMove(_ notation: String) -> CubeState {
    var state = CubeState.solved()
    
    // Parse notation to determine move and direction
    let cleanNotation = notation.trimmingCharacters(in: .whitespaces)
    
    // Determine direction
    let direction: CubeMoveDirection
    if cleanNotation.hasSuffix("2") {
        direction = .double
    } else if cleanNotation.hasSuffix("'") {
        direction = .counterClockwise
    } else {
        direction = .clockwise
    }
    
    // Get base move (without modifier)
    let baseMove = cleanNotation.hasSuffix("2") || cleanNotation.hasSuffix("'")
        ? String(cleanNotation.dropLast())
        : cleanNotation
    
    // Apply the appropriate move
    switch baseMove {
    case "R":
        state.apply(CubeMove(face: .right, direction: direction))
    case "L":
        state.apply(CubeMove(face: .left, direction: direction))
    case "U":
        state.apply(CubeMove(face: .up, direction: direction))
    case "D":
        state.apply(CubeMove(face: .down, direction: direction))
    case "F":
        state.apply(CubeMove(face: .front, direction: direction))
    case "B":
        state.apply(CubeMove(face: .back, direction: direction))
    case "M":
        state.apply(CubeMove(slice: .middle, direction: direction))
    case "E":
        state.apply(CubeMove(slice: .equator, direction: direction))
    case "S":
        state.apply(CubeMove(slice: .standing, direction: direction))
    case "x":
        state.apply(CubeMove(rotation: .x, direction: direction))
    case "y":
        state.apply(CubeMove(rotation: .y, direction: direction))
    case "z":
        state.apply(CubeMove(rotation: .z, direction: direction))
    default:
        break
    }
    
    return state
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

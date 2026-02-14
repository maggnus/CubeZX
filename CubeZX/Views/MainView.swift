//
//  MainView.swift
//  CubeZX
//
//  Main view with centered cube
//

import Logging
import SwiftUI

@available(macOS 14.0, *)
struct MainView: View {
    @StateObject private var model = CubeAppModel()
    @Environment(\.theme) private var theme
    @State private var showNotationPopup = false

    private let logger = Logger(label: "com.qwibi.cubezx.\(MainView.self)")

    var body: some View {
        ZStack {
            // Cube - always centered
            CubeSceneView(
                cubeState: model.cubeState,
                pendingMove: model.pendingMove,
                shouldReset: model.shouldReset,
                shouldSyncState: model.shouldSyncState,
                quatW: model.quatW,
                quatX: model.quatX,
                quatY: model.quatY,
                quatZ: model.quatZ,
                onMoveAnimated: model.onMoveAnimated,
                onResetComplete: model.onResetComplete,
                onStateSyncComplete: model.onStateSyncComplete,
                onUserInteraction: model.onUserInteraction,
                onDragUpdate: { x, y, z, w in
                    model.updateUserOffset(
                        viewQuatX: x, viewQuatY: y, viewQuatZ: z, viewQuatW: w)
                },
                onDragEnd: model.onDragEnded
            )
        }
        .focusable()
        .onKeyPress { handleKeyPress($0) }
        .overlay {
            if showNotationPopup {
                CZXPopup(
                    title: "Notation",
                    maxWidth: 500,
                    maxHeight: 450,
                    onClose: { showNotationPopup = false }
                ) {
                    NotationPopup {
                        showNotationPopup = false
                    }
                }
            }
        }
    }

    private func handleKeyPress(_ key: KeyPress) -> KeyPress.Result {
        let letter = key.characters.uppercased()
        let isShift = key.modifiers.contains(.shift)
        let direction: CubeMoveDirection = isShift ? .counterClockwise : .clockwise

        logger.info("Key pressed: \(letter)", metadata: ["source": .string("Keyboard")])

        // Handle notation popup toggle
        if letter == "N" {
            showNotationPopup.toggle()
            return .handled
        }

        var move: CubeMove?
        let mapping = model.faceMapping

        switch letter {
        case "L": move = CubeMove(face: mapping.actualFace(for: .left), direction: direction)
        case "R": move = CubeMove(face: mapping.actualFace(for: .right), direction: direction)
        case "U": move = CubeMove(face: mapping.actualFace(for: .up), direction: direction)
        case "D": move = CubeMove(face: mapping.actualFace(for: .down), direction: direction)
        case "F": move = CubeMove(face: mapping.actualFace(for: .back), direction: direction)
        case "B": move = CubeMove(face: mapping.actualFace(for: .front), direction: direction)
        case "M": move = CubeMove(slice: .middle, direction: direction)
        case "E": move = CubeMove(slice: .equator, direction: direction)
        case "S": move = CubeMove(slice: .standing, direction: direction)
        case "X":
            move = CubeMove(rotation: .x, direction: direction)
            model.applyRotation(.x, direction: direction)
        case "Y":
            move = CubeMove(rotation: .y, direction: direction)
            model.applyRotation(.y, direction: direction)
        case "Z":
            move = CubeMove(rotation: .z, direction: direction)
            model.applyRotation(.z, direction: direction)
        case "Q":
            model.resetCube()
            return .handled
        default: break
        }

        if let move {
            logger.info("Sending move: \(move.notation)", metadata: ["source": .string("Keyboard")])
            model.keyboardAdapter.sendMove(move)
            return .handled
        }
        return .ignored
    }
}

@available(macOS 14.0, *)
#Preview {
    MainView()
        .environment(Theme.shared)
}

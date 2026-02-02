//
//  ContentView.swift
//  CubeZX
//
//  Created by Maksim Korenev on 28/1/26.
//

import SwiftUI
import Logging

@available(macOS 14.0, *)
struct ContentView: View {
    @StateObject private var model = CubeAppModel()
    
    private let logger = Logger(label: "com.qwibi.cubezx.\(ContentView.self)")

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color.blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
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
                            model.updateUserOffset(viewQuatX: x, viewQuatY: y, viewQuatZ: z, viewQuatW: w)
                        },
                        onDragEnd: model.onDragEnded
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    
                    if model.isDebugModeEnabled && model.showDebugOverlay {
                        DebugTerminalOverlay()
                        CubeInfoOverlay(model: model)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }

            VStack {
                HStack {
                    Button(action: { model.startDiscovery() }) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    ConnectionStatusView(model: model)

                    Spacer()

                    Button(action: { model.isNotationPresented.toggle() }) {
                        Image(systemName: "n.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { model.isDebugPresented.toggle() }) {
                        Image(systemName: model.isDebugPresented ? "ladybug.fill" : "ladybug")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                Spacer()
                HStack {
                    Button(action: { model.resetCube() }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.leading)
                    
                    Button(action: { model.resyncCube() }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }

            if model.isDiscoveryPresented {
                DiscoveryPopup(model: model)
            }
            
            if model.isNotationPresented {
                NotationPopup(onClose: { model.isNotationPresented = false })
            }
            
            if model.isDebugPresented {
                DebugPopup(
                    isDebugEnabled: $model.isDebugModeEnabled,
                    showRawData: $model.showRawBLEData,
                    showOverlay: $model.showDebugOverlay,
                    showGyroDebug: $model.showGyroDebug,
                    showDecodedPayload: $model.showDecodedPayload,
                    onClose: { model.isDebugPresented = false }
                )
            }

        }
        .focusable()
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }

    @available(macOS 14.0, *)
    private func handleKeyPress(_ key: KeyPress) -> KeyPress.Result {
        let letter = key.characters.uppercased()
        let isShift = key.modifiers.contains(.shift)
        let direction: CubeMoveDirection = isShift ? .counterClockwise : .clockwise

        logger.info("Key pressed: \(letter)", metadata: ["source": .string("Keyboard")])

        var move: CubeMove?
        let mapping = model.faceMapping
        
        switch letter {
        case "L": move = CubeMove(face: mapping.actualFace(for: .left), direction: direction)
        case "R": move = CubeMove(face: mapping.actualFace(for: .right), direction: direction)
        case "U": move = CubeMove(face: mapping.actualFace(for: .up), direction: direction)
        case "D": move = CubeMove(face: mapping.actualFace(for: .down), direction: direction)
        case "F": move = CubeMove(face: mapping.actualFace(for: .front), direction: direction)
        case "B": move = CubeMove(face: mapping.actualFace(for: .back), direction: direction)
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
        case "N":
            model.isNotationPresented.toggle()
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
    ContentView()
}

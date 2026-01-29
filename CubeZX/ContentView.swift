//
//  ContentView.swift
//  CubeZX
//
//  Created by Maksim Korenev on 28/1/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = CubeAppModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color.blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    CubeSceneView(cubeState: model.cubeState, pendingMove: model.pendingMove, shouldReset: model.shouldReset, onMoveAnimated: model.onMoveAnimated, onResetComplete: model.onResetComplete, onOrientationChanged: model.updateOrientation)
                        .frame(width: geo.size.width, height: geo.size.height)
                    
                    if model.isDebugPresented {
                        DebugTerminalOverlay(logger: model.debugLogger)
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
                    .padding()

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

        }
        .focusable()
        .onKeyPress { keyPress in
            handleKeyPress(keyPress)
        }
    }

    private func handleKeyPress(_ key: KeyPress) -> KeyPress.Result {
        let letter = key.characters.uppercased()
        let isShift = key.modifiers.contains(.shift)
        let direction: CubeMoveDirection = isShift ? .counterClockwise : .clockwise

        model.debugLogger.log("Key pressed: \(letter)", source: "Keyboard")

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
            model.debugLogger.log("Sending move: \(move.notation)", source: "Keyboard")
            model.keyboardAdapter.sendMove(move)
            return .handled
        }
        return .ignored
    }
}

#Preview {
    ContentView()
}

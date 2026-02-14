//
//  ContentView.swift
//  CubeZX
//
//  Minimal wrapper view
//

import SwiftUI

@available(macOS 14.0, *)
struct ContentView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        theme.colors.background.primary
            .ignoresSafeArea()
            .overlay {
                MainView()
            }
    }
}

@available(macOS 14.0, *)
#Preview {
    ContentView()
        .environment(Theme.shared)
}

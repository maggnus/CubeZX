//
//  CubeZXApp.swift
//  CubeZX
//
//  Entry point with theme injection
//

import SwiftUI

@main
struct CubeZXApp: App {
    @State private var theme = Theme.shared
    
    var body: some Scene {
        WindowGroup {
            if #available(macOS 14.0, *) {
                ContentView()
                    .environment(theme)
                    .preferredColorScheme(.dark)
            } else {
                Text("This app requires macOS 14.0 or later.")
            }
        }
    }
}

//
//  CubeZXApp.swift
//  CubeZX
//
//  Created by Maksim Korenev on 28/1/26.
//

import SwiftUI

@main
struct CubeZXApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 14.0, *) {
                ContentView()
            } else {
                Text("This app requires macOS 14.0 or later.")
            }
        }
    }
}

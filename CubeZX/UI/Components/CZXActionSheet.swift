//
//  CZXActionSheet.swift
//  CubeZX
//
//  Action sheet component with theme support
//

import SwiftUI

/// A themed action sheet that slides up from the bottom
struct CZXActionSheet<Content: View>: View {
    @Environment(\.theme) private var theme
    
    let title: String?
    let content: Content
    let onClose: () -> Void
    
    init(
        title: String? = nil,
        onClose: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            theme.colors.background.primary
                .opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            // Action sheet content (bottom aligned)
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.colors.text.tertiary)
                        .frame(width: 36, height: 4)
                        .padding(.top, theme.spacing.small)
                        .padding(.bottom, theme.spacing.medium)
                    
                    // Title
                    if let title = title {
                        HStack {
                            Text(title)
                                .font(theme.typography.title3)
                                .foregroundColor(theme.colors.text.primary)
                            Spacer()
                        }
                        .padding(.horizontal, theme.spacing.medium)
                        .padding(.bottom, theme.spacing.small)
                    }
                    
                    // Content
                    content
                        .padding(.horizontal, theme.spacing.medium)
                        .padding(.bottom, theme.spacing.medium)
                }
                .background(
                    ZStack {
                        // Glass background
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xLarge)
                            .fill(.ultraThinMaterial)
                        
                        // Gradient overlay
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xLarge)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.colors.background.secondary.opacity(0.5),
                                        theme.colors.background.secondary.opacity(0.3)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.xLarge)
                        .stroke(theme.colors.border.primary, lineWidth: 1)
                )
                .padding(.horizontal, theme.spacing.small)
                .padding(.bottom, theme.spacing.small)
            }
        }
    }
}

// MARK: - Action Sheet Modifier

extension View {
    /// Presents an action sheet when a condition is true
    func czxActionSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        overlay(
            Group {
                if isPresented.wrappedValue {
                    CZXActionSheet(
                        title: title,
                        onClose: { isPresented.wrappedValue = false }
                    ) {
                        content()
                    }
                }
            }
        )
    }
}

// MARK: - Previews

@available(macOS 14.0, *)
#Preview("CZXActionSheet") {
    ZStack {
        Theme.shared.colors.background.primary
            .ignoresSafeArea()
        
        CZXActionSheet(title: "Options", onClose: {}) {
            VStack(spacing: 12) {
                CZXPrimaryButton("Connect", icon: "bolt.fill") {}
                CZXSecondaryButton("Cancel") {}
            }
        }
    }
    .environment(Theme.shared)
}

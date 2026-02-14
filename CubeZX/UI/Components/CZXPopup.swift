//
//  CZXPopup.swift
//  CubeZX
//
//  Popup/Modal component with glassmorphic style
//

import SwiftUI

/// A glassmorphic popup/modal container
struct CZXPopup<Content: View>: View {
    @Environment(\.theme) private var theme
    
    let title: String?
    let content: Content
    let onClose: () -> Void
    let maxWidth: CGFloat
    let maxHeight: CGFloat?
    
    init(
        title: String? = nil,
        maxWidth: CGFloat = 400,
        maxHeight: CGFloat? = nil,
        onClose: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.onClose = onClose
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Backdrop - blurred and semi-transparent
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            // Popup content
            VStack(spacing: 0) {
                // Header
                if let title = title {
                    HStack {
                        Text(title)
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.text.primary)
                        
                        Spacer()
                        
                        CloseButton(action: onClose)
                    }
                    .padding(.horizontal, theme.spacing.medium)
                    .padding(.vertical, theme.spacing.small)
                }
                
                // Content
                content
                    .padding(theme.spacing.medium)
            }
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: theme.cornerRadius.xLarge)
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay - more transparent
                    RoundedRectangle(cornerRadius: theme.cornerRadius.xLarge)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.colors.background.secondary.opacity(0.3),
                                    theme.colors.background.secondary.opacity(0.15)
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
            .shadow(
                color: theme.shadows.large.color,
                radius: theme.shadows.large.radius,
                x: theme.shadows.large.x,
                y: theme.shadows.large.y
            )
            .padding(theme.spacing.medium)
        }
    }
}

// MARK: - Close Button

private struct CloseButton: View {
    @Environment(\.theme) private var theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.text.secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(theme.colors.background.glass)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Popup Modifier

extension View {
    /// Presents a popup when a condition is true
    func czxPopup<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        maxWidth: CGFloat = 400,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        overlay(
            Group {
                if isPresented.wrappedValue {
                    CZXPopup(
                        title: title,
                        maxWidth: maxWidth,
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

#Preview("CZXPopup") {
    ZStack {
        Theme.shared.colors.background.primary
            .ignoresSafeArea()
        
        CZXPopup(
            title: "Settings",
            onClose: {}
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Connection")
                    .font(.caption)
                    .foregroundColor(Theme.shared.colors.text.secondary)
                
                HStack {
                    Text("Bluetooth Device")
                        .foregroundColor(.white)
                    Spacer()
                    Text("Tornado V4")
                        .foregroundColor(Theme.shared.colors.text.secondary)
                }
                
                Divider()
                    .background(Theme.shared.colors.border.primary)
                
                CZXSecondaryButton("Connect", icon: "bolt.fill") {}
            }
        }
    }
    .environment(Theme.shared)
}

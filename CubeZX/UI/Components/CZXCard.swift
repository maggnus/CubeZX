//
//  CZXCard.swift
//  CubeZX
//
//  Glassmorphic card component
//

import SwiftUI

/// A glassmorphic card container with frosted glass effect
struct CZXCard<Content: View>: View {
    @Environment(\.theme) private var theme
    
    let content: Content
    let padding: CGFloat
    let showBorder: Bool
    
    init(
        padding: CGFloat? = nil,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding ?? Theme.shared.spacing.medium
        self.showBorder = showBorder
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Frosted glass background
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.colors.background.glass.opacity(1.5),
                                    theme.colors.background.glass
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(
                        showBorder ? theme.colors.border.primary : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: theme.shadows.medium.color,
                radius: theme.shadows.medium.radius,
                x: theme.shadows.medium.x,
                y: theme.shadows.medium.y
            )
    }
}

// MARK: - Badge

struct CZXBadge: View {
    @Environment(\.theme) private var theme
    
    let text: String
    let icon: String?
    let color: Color
    
    init(
        _ text: String,
        icon: String? = nil,
        color: Color? = nil
    ) {
        self.text = text
        self.icon = icon
        self.color = color ?? Theme.shared.colors.accent.primary
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.xxSmall) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(theme.typography.caption2)
            }
            Text(text)
                .font(theme.typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, theme.spacing.small)
        .padding(.vertical, theme.spacing.xxSmall)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Previews

#Preview("CZXCard") {
    ZStack {
        Theme.shared.colors.background.primary
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            CZXCard {
                VStack(alignment: .leading) {
                    Text("Card Title")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Card content goes here")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            CZXBadge("Connected", icon: "checkmark.circle.fill", color: .green)
            CZXBadge("Timer", color: .orange)
        }
        .padding()
    }
    .environment(Theme.shared)
}

//
//  CZXButton.swift
//  CubeZX
//
//  Button components using theme system
//

import SwiftUI

// MARK: - Icon Button

/// Circular icon button with glassmorphic style
struct CZXIconButton: View {
    @Environment(\.theme) private var theme
    
    let icon: String
    let action: () -> Void
    let size: CGFloat
    
    init(icon: String, size: CGFloat = 40, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(theme.colors.text.primary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(theme.colors.border.primary, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Primary Button

/// Primary action button with accent color
struct CZXPrimaryButton: View {
    @Environment(\.theme) private var theme
    
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.xSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(theme.typography.subheadline)
            .foregroundColor(theme.colors.background.primary)
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.small)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .fill(theme.colors.accent.primary)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary Button

/// Secondary button with glass effect
struct CZXSecondaryButton: View {
    @Environment(\.theme) private var theme
    
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.xSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(theme.typography.subheadline)
            .foregroundColor(theme.colors.text.primary)
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.small)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                            .stroke(theme.colors.border.primary, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Bar

/// Bottom tab bar with glassmorphic background
struct CZXTabBar: View {
    @Environment(\.theme) private var theme
    
    let tabs: [TabItem]
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: theme.spacing.xxSmall) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        Text(tab.label)
                            .font(theme.typography.caption2)
                    }
                    .foregroundColor(selectedTab == index ? theme.colors.accent.primary : theme.colors.text.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.small)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, theme.spacing.small)
        .padding(.vertical, theme.spacing.xxSmall)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .stroke(theme.colors.border.primary, lineWidth: 1)
                )
        )
    }
}

// MARK: - Tab Item

struct TabItem {
    let icon: String
    let label: String
}

// MARK: - Previews

#Preview("CZXButtons") {
    ZStack {
        Theme.shared.colors.background.primary
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                CZXIconButton(icon: "gear") {}
                CZXIconButton(icon: "bell") {}
                CZXIconButton(icon: "person") {}
            }
            
            CZXPrimaryButton("Primary", icon: "play.fill") {}
            CZXSecondaryButton("Secondary", icon: "arrow.clockwise") {}
            
            CZXTabBar(
                tabs: [
                    TabItem(icon: "cube", label: "Cube"),
                    TabItem(icon: "stopwatch", label: "Timer"),
                    TabItem(icon: "book", label: "Learn"),
                    TabItem(icon: "ellipsis", label: "More")
                ],
                selectedTab: .constant(0)
            )
        }
        .padding()
    }
    .environment(Theme.shared)
}

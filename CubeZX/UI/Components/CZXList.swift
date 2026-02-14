//
//  CZXList.swift
//  CubeZX
//
//  List components with theme support
//

import SwiftUI

// MARK: - List Container

/// A themed list container with glassmorphic background
struct CZXList<Content: View>: View {
    @Environment(\.theme) private var theme
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        CZXCard(padding: 0) {
            VStack(spacing: 0) {
                content
            }
        }
    }
}

// MARK: - List Row

/// A single row item in a list
struct CZXListRow: View {
    @Environment(\.theme) private var theme
    
    let icon: String?
    let title: String
    let value: String?
    let showChevron: Bool
    let action: (() -> Void)?
    
    init(
        icon: String? = nil,
        title: String,
        value: String? = nil,
        showChevron: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: theme.spacing.small) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.accent.primary)
                        .frame(width: 24)
                }
                
                // Title
                Text(title)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.text.primary)
                
                Spacer()
                
                // Value
                if let value = value {
                    Text(value)
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.text.secondary)
                }
                
                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.text.tertiary)
                }
            }
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.small)
        }
        .buttonStyle(CZXListRowStyle())
    }
}

// MARK: - Custom List Row

struct CZXCustomListRow<Content: View>: View {
    @Environment(\.theme) private var theme
    
    let content: Content
    let action: (() -> Void)?
    
    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: { action?() }) {
            content
                .padding(.horizontal, theme.spacing.medium)
                .padding(.vertical, theme.spacing.small)
        }
        .buttonStyle(CZXListRowStyle())
    }
}

// MARK: - List Row Style

private struct CZXListRowStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? theme.colors.background.glass.opacity(2)
                    : Color.clear
            )
    }
}

// MARK: - List Section Header

/// A section header for grouping list items
struct CZXListSectionHeader: View {
    @Environment(\.theme) private var theme
    
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(theme.typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(theme.colors.text.secondary)
            .padding(.horizontal, theme.spacing.medium)
            .padding(.vertical, theme.spacing.xSmall)
    }
}

// MARK: - Divider

struct CZXDivider: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        Divider()
            .background(theme.colors.border.primary)
    }
}

// MARK: - Previews

#Preview("CZXList") {
    ZStack {
        Theme.shared.colors.background.primary
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 24) {
                // Simple list
                CZXList {
                    CZXListRow(icon: "gear", title: "Settings") {}
                    CZXDivider()
                    CZXListRow(icon: "person", title: "Profile") {}
                    CZXDivider()
                    CZXListRow(icon: "bell", title: "Notifications") {}
                }
                
                // List with values
                CZXList {
                    CZXListRow(icon: "cube", title: "Device", value: "Tornado V4") {}
                    CZXDivider()
                    CZXListRow(icon: "battery.75", title: "Battery", value: "84%") {}
                    CZXDivider()
                    CZXListRow(icon: "clock", title: "Timer", value: "14.52s") {}
                }
                
                // Custom content
                CZXList {
                    CZXCustomListRow {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.green)
                            Text("Connection Status")
                                .foregroundColor(.white)
                            Spacer()
                            CZXBadge("Connected", color: .green)
                        }
                    }
                }
                
                // With section header
                VStack(alignment: .leading, spacing: 0) {
                    CZXListSectionHeader(title: "Device Info")
                    CZXList {
                        CZXListRow(title: "MAC Address", value: "A4:C1:38:XX:XX") {}
                    }
                }
            }
            .padding()
        }
    }
    .environment(Theme.shared)
}

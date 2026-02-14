//
//  Theme.swift
//  CubeZX
//
//  Comprehensive theme system for consistent UI
//

import SwiftUI
import Observation

// MARK: - Theme Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .shared
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Theme

@Observable
final class Theme {
    static let shared = Theme()
    
    var colors: Colors
    var typography: Typography
    var spacing: Spacing
    var cornerRadius: CornerRadius
    var shadows: Shadows
    
    init(
        colors: Colors = .dark,
        typography: Typography = .default,
        spacing: Spacing = .default,
        cornerRadius: CornerRadius = .default,
        shadows: Shadows = .default
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.shadows = shadows
    }
}

// MARK: - Colors

extension Theme {
    struct Colors {
        let background: BackgroundColors
        let accent: AccentColors
        let text: TextColors
        let border: BorderColors
        
        static let dark = Colors(
            background: .dark,
            accent: .default,
            text: .dark,
            border: .dark
        )
    }
    
    struct BackgroundColors {
        let primary: Color      // Deep void
        let secondary: Color    // Midnight
        let tertiary: Color     // Slate
        let quaternary: Color   // Graphite
        let glass: Color        // For glassmorphic effects
        
        static let dark = BackgroundColors(
            primary: Color(hex: "#0A0A0F"),
            secondary: Color(hex: "#12121A"),
            tertiary: Color(hex: "#1E1E2E"),
            quaternary: Color(hex: "#2A2A3A"),
            glass: Color.white.opacity(0.05)
        )
    }
    
    struct AccentColors {
        let primary: Color      // Neon Cyan
        let secondary: Color    // Electric Blue
        let success: Color      // Matrix Green
        let warning: Color      // Solar Orange
        let error: Color        // Alert Red
        let special: Color      // Plasma Purple
        
        static let `default` = AccentColors(
            primary: Color(hex: "#00D9FF"),
            secondary: Color(hex: "#0080FF"),
            success: Color(hex: "#00FF88"),
            warning: Color(hex: "#FF6B35"),
            error: Color(hex: "#FF3366"),
            special: Color(hex: "#B829DD")
        )
    }
    
    struct TextColors {
        let primary: Color
        let secondary: Color
        let tertiary: Color
        let disabled: Color
        let inverse: Color
        
        static let dark = TextColors(
            primary: .white,
            secondary: Color.white.opacity(0.7),
            tertiary: Color.white.opacity(0.4),
            disabled: Color.white.opacity(0.25),
            inverse: Color.black
        )
    }
    
    struct BorderColors {
        let primary: Color
        let secondary: Color
        let accent: Color
        
        static let dark = BorderColors(
            primary: Color.white.opacity(0.1),
            secondary: Color.white.opacity(0.05),
            accent: Color(hex: "#00D9FF").opacity(0.3)
        )
    }
}

// MARK: - Typography

extension Theme {
    struct Typography {
        let hero: Font
        let title1: Font
        let title2: Font
        let title3: Font
        let headline: Font
        let body: Font
        let callout: Font
        let subheadline: Font
        let footnote: Font
        let caption: Font
        let caption2: Font
        
        static let `default` = Typography(
            hero: .system(size: 48, weight: .bold, design: .default),
            title1: .system(size: 34, weight: .bold, design: .default),
            title2: .system(size: 28, weight: .semibold, design: .default),
            title3: .system(size: 22, weight: .medium, design: .default),
            headline: .system(size: 17, weight: .semibold, design: .default),
            body: .system(size: 17, weight: .regular, design: .default),
            callout: .system(size: 16, weight: .medium, design: .default),
            subheadline: .system(size: 15, weight: .regular, design: .default),
            footnote: .system(size: 13, weight: .regular, design: .default),
            caption: .system(size: 12, weight: .medium, design: .default),
            caption2: .system(size: 11, weight: .medium, design: .default)
        )
    }
}

// MARK: - Spacing

extension Theme {
    struct Spacing {
        let xxxSmall: CGFloat
        let xxSmall: CGFloat
        let xSmall: CGFloat
        let small: CGFloat
        let medium: CGFloat
        let large: CGFloat
        let xLarge: CGFloat
        let xxLarge: CGFloat
        let xxxLarge: CGFloat
        
        static let `default` = Spacing(
            xxxSmall: 2,
            xxSmall: 4,
            xSmall: 8,
            small: 12,
            medium: 16,
            large: 20,
            xLarge: 24,
            xxLarge: 32,
            xxxLarge: 48
        )
    }
}

// MARK: - Corner Radius

extension Theme {
    struct CornerRadius {
        let none: CGFloat
        let small: CGFloat
        let medium: CGFloat
        let large: CGFloat
        let xLarge: CGFloat
        let max: CGFloat
        
        static let `default` = CornerRadius(
            none: 0,
            small: 8,
            medium: 12,
            large: 16,
            xLarge: 20,
            max: 999
        )
    }
}

// MARK: - Shadows

extension Theme {
    struct Shadows {
        let none: Shadow
        let small: Shadow
        let medium: Shadow
        let large: Shadow
        let glow: Shadow
        
        static let `default` = Shadows(
            none: Shadow(color: .clear, radius: 0, x: 0, y: 0),
            small: Shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2),
            medium: Shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4),
            large: Shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8),
            glow: Shadow(color: Color(hex: "#00D9FF").opacity(0.3), radius: 15, x: 0, y: 0)
        )
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        func apply<V: View>(to view: V) -> some View {
            view.shadow(color: color, radius: radius, x: x, y: y)
        }
    }
}

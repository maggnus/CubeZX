import SwiftUI

struct BlurView: View {
    let style: BlurStyle

    var body: some View {
        Representable(style: style)
            .accessibilityHidden(true)
    }
}

enum BlurStyle {
    case regular
}

#if os(iOS)
private struct Representable: UIViewRepresentable {
    let style: BlurStyle

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blur = UIBlurEffect(style: .systemMaterial)
        return UIVisualEffectView(effect: blur)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
    }
}
#elseif os(macOS)
private struct Representable: NSViewRepresentable {
    let style: BlurStyle

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .withinWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}
#endif

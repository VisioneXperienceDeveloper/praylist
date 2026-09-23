import SwiftUI
import UIKit

extension Color {
    static let ink = Color("Ink")
    static let paper = Color("Paper")
    static let forest = Color("AccentColor")
    static let quiet = Color("Quiet")
}

struct PaperBackground: View {
    var body: some View {
        Color.paper.overlay(alignment: .topTrailing) {
            Ellipse().fill(Color.forest.opacity(0.055)).frame(width: 320, height: 470).blur(radius: 75).offset(x: 150, y: -160)
        }.ignoresSafeArea()
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Spacer(); Text(title).fontWeight(.semibold); Image(systemName: symbol); Spacer() }
                .padding(.vertical, 12).foregroundStyle(Color("OnAccent"))
        }.modifier(PrimaryStyle())
    }
}
private struct PrimaryStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) { content.buttonStyle(.glassProminent).tint(.forest) }
        else { content.buttonStyle(.borderedProminent).tint(.forest).buttonBorderShape(.capsule) }
    }
}

struct GlassGroup<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        if #available(iOS 26, *) { GlassEffectContainer(spacing: 16) { content() } }
        else { content() }
    }
}

struct GlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) { content.glassEffect(.regular.interactive(), in: .circle) }
        else { content.background(.regularMaterial, in: .circle) }
    }
}

struct BookMark: View {
    var size: CGFloat = 100
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26).fill(Color.forest.gradient)
            Image(systemName: "book").font(.system(size: size * 0.43, weight: .light)).foregroundStyle(Color(red: 0.98, green: 0.95, blue: 0.84)).offset(y: size * 0.045)
            Image(systemName: "sparkle").font(.system(size: size * 0.20, weight: .light)).foregroundStyle(Color(red: 0.98, green: 0.95, blue: 0.84)).offset(x: size * 0.20, y: -size * 0.22)
        }.frame(width: size, height: size)
    }
}

struct AppStoreIcon: View {
    var size: CGFloat = 100

    var body: some View {
        Group {
            if let image = UIImage.appStoreIcon {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                BookMark(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
        .accessibilityHidden(true)
    }
}

private extension UIImage {
    static var appStoreIcon: UIImage? {
        guard
            let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String]
        else { return UIImage(named: "AppIcon") }
        return files.reversed().compactMap { UIImage(named: $0) }.first
    }
}

struct SheetHeader: ViewModifier {
    func body(content: Content) -> some View {
        content.scrollContentBackground(.hidden).background(Color.paper).foregroundStyle(Color.ink)
    }
}

extension View {
    func paperSheet() -> some View { modifier(SheetHeader()) }
    func errorAlert(_ message: Binding<String?>) -> some View {
        alert(L10n.text("다시 확인해 주세요"), isPresented: Binding(get: { message.wrappedValue != nil }, set: { if !$0 { message.wrappedValue = nil } })) {
            Button(L10n.text("확인"), role: .cancel) { message.wrappedValue = nil }
        } message: { Text(message.wrappedValue ?? "") }
    }
}

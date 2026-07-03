//
//  ViewExtensions.swift
//  PlayCover
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

extension View {
    func toastOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            return self.safeAreaBar(edge: .bottom, content: content)
        }
        #endif
        return self.overlay(content: content)
    }

    func toastBackground() -> some View {
        let view = self
            .padding()
            .frame(maxWidth: .infinity)

        // provide default padding for older systems, but for those with liquid glass available, add proper padding to
        // left, right, and bottom to ensure that the distance from the edges of the app are consistent and equal
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            return view.glassEffect(.regular, in: .containerRelative)
                .padding(ToastView.toastGlassPadding)
                .padding(.top)
        }
        #endif
        return view.background(.regularMaterial, in: .containerRelative)
            .padding()
    }

    // MARK: - Liquid Glass helpers

    /// Background suitable for selectable library cells (grid/list items).
    /// On macOS 26+ it uses a subtle glass effect; on older systems it falls back to material/color.
    func libraryCellBackground(isSelected: Bool, selectedColor: Color) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            return AnyView(
                self
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isSelected ? selectedColor.opacity(0.35) : Color.clear)
                            .glassEffect(.regular, in: .rect(cornerRadius: 18))
                    )
            )
        }
        #endif
        return AnyView(
            self
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? selectedColor : Color.clear)
                        .brightness(-0.2)
                )
        )
    }

    /// A card-like glass container for settings panels and modal headers.
    func glassCard(cornerRadius: CGFloat = 18) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            return AnyView(
                self
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.clear)
                            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                    )
            )
        }
        #endif
        return AnyView(
            self
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.regularMaterial)
                )
        )
    }

    /// Applies a translucent sidebar background on macOS 26+ using the native
    /// sidebar material; falls back to the default background on older systems.
    func glassSidebarBackground() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            return AnyView(self.background(SidebarGlassBackground()))
        }
        #endif
        return AnyView(self)
    }
}

#if compiler(>=6.2)
@available(macOS 26.0, *)
struct SidebarGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> some NSView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {}
}
#endif

import SwiftUI
import Cocoa

/// A custom shape that allows distinct corner radii for the four corners.
/// Essential for drawing a Notch view that seamlessly joins the top screen bezel
/// (or the physical hardware notch) by setting a `0` top radius.
struct NotchShape: Shape {
    var topCornerRadius: CGFloat = 0.0 // The top must remain 0 to blend naturally to the screen bezel
    var bottomCornerRadius: CGFloat = 18.0 // The curved bottom mimicking a physical notch
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)
        let bl = CGPoint(x: rect.minX, y: rect.maxY)
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + topCornerRadius))
        
        // Top Left Corner
        path.addArc(tangent1End: tl, tangent2End: CGPoint(x: rect.minX + topCornerRadius, y: rect.minY), radius: topCornerRadius)
        
        // Top Right Corner
        path.addArc(tangent1End: tr, tangent2End: CGPoint(x: rect.maxX, y: rect.minY + topCornerRadius), radius: topCornerRadius)
        
        // Bottom Right Corner
        path.addArc(tangent1End: br, tangent2End: CGPoint(x: rect.maxX - bottomCornerRadius, y: rect.maxY), radius: bottomCornerRadius)
        
        // Bottom Left Corner
        path.addArc(tangent1End: bl, tangent2End: CGPoint(x: rect.minX, y: rect.maxY - bottomCornerRadius), radius: bottomCornerRadius)
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Core Implementation for a Floating Notch Window

/// This NSPanel implementation makes sure the window sits above menus, avoids shadows at the top,
/// and is properly configured for the Apple workspace.
class NotchPanel: NSPanel {
    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            // Style needed to avoid standard window borders but float at the top
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: backing,
            defer: flag
        )
        
        self.isFloatingPanel = true
        self.isOpaque = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.backgroundColor = .clear // Transparent base
        self.isMovable = false
        
        self.collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]
        
        self.isReleasedWhenClosed = false
        // Make sure it sits exactly below cursor/screen stuff, but ABOVE the menu bar!
        self.level = NSWindow.Level.mainMenu + 3
        self.hasShadow = false // Shadow is calculated via SwiftUI shape instead
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// A manager used to mount and position a SwiftUI view inside an NSPanel seamlessly at the top center.
class NotchManager {
    static let shared = NotchManager()
    private var window: NotchPanel?
    
    /// Shows a given view as a native macOS notch.
    func showNotch<Content: View>(width: CGFloat = 320, height: CGFloat = 40, @ViewBuilder content: @escaping () -> Content) {
        if window == nil {
            let notchContent = content()
                .background(Theme.Palette.ink)
                .foregroundStyle(Theme.Palette.canvas)
                .clipShape(NotchShape(topCornerRadius: 0, bottomCornerRadius: height / 2.5))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 5)
            
            let hostingView = NSHostingView(rootView: notchContent)
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
            
            let panel = NotchPanel(
                contentRect: hostingView.bounds,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.contentView = hostingView
            self.window = panel
        }
        
        guard let window = self.window, let screen = NSScreen.main else { return }
        
        // Center the notch accurately against the display width and pin it to the very Y-max!
        let screenFrame = screen.frame
        let notchWidth = window.frame.width
        let notchHeight = window.frame.height
        
        window.setFrame(NSRect(
            x: screenFrame.midX - notchWidth / 2,
            y: screenFrame.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        ), display: true)
        
        window.orderFrontRegardless()
    }
    
    // Hide or release the active Notch
    func hideNotch() {
        window?.orderOut(nil)
    }
}

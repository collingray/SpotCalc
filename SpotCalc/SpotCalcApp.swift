import SwiftUI
import AppKit

@main
struct SpotCalcApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minHeight: 150)
                .clipShape(RoundedRectangle(cornerRadius: 15.0))
                .edgesIgnoringSafeArea(.top)
        }
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            self.window = window
            
            window.center()
            window.delegate = self
            window.isOpaque = false
            window.backgroundColor = .clear
//            window.isMovableByWindowBackground = true
            window.level = .floating
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.styleMask.insert([.resizable, .fullSizeContentView])
            window.invalidateShadow()
            //            window.minSize = NSSize(width: 600, height: 100)  // Minimum size to maintain a fixed width
            //            window.maxSize = NSSize(width: 600, height: CGFloat.greatestFiniteMagnitude)  // Maximum height to allow vertical resizing
            
            //            registerHotkey()
        }
    }

    func registerHotkey() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        guard trusted else {
            print("App is not trusted for accessibility.")
            return
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { (event) in
            if event.modifierFlags.contains(.command) && event.keyCode == 49 { // Command + Space
                self.toggleWindow()
            }
        }
    }

    func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

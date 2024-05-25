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
            window.isMovableByWindowBackground = true
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
            
            registerHotkey()
        }
    }
    
    func checkToggleEvent(event: NSEvent) -> Bool {
        return event.modifierFlags.contains(.control) &&
        event.modifierFlags.contains(.option) &&
        event.modifierFlags.contains(.command) &&
        event.keyCode == 49 // space
    }

    func registerHotkey() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        guard trusted else {
            print("App is not trusted for accessibility.")
            return
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { (event) in
            if self.checkToggleEvent(event: event) {
                self.toggleWindow()
            }
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) in
            if self.checkToggleEvent(event: event) {
                self.toggleWindow()
                return nil
            }
            
            return event
        }
    }
    
//    func windowDidMove(_ notification: Notification) {
//        guard let window = notification.object as? NSWindow else { return }
//
//        let snapThreshold: CGFloat = 20
//        let targetPosition = NSPoint(x: 100, y: 100)  // Example target position
//
//        let windowFrame = window.frame
//        let deltaX = abs(windowFrame.origin.x - targetPosition.x)
//        let deltaY = abs(windowFrame.origin.y - targetPosition.y)
//        
//        print(windowFrame)
//        
//        if deltaX < snapThreshold && deltaY < snapThreshold {
//            window.setFrameOrigin(targetPosition)
//        }
//    }

    func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
        }
    }
}

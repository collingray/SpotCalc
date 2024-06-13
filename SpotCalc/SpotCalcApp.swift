import SwiftUI
import AppKit

@main
struct SpotCalcApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @State private var settingsData = SettingsData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minHeight: 150)
                .clipShape(RoundedRectangle(cornerRadius: 15.0))
                .edgesIgnoringSafeArea(.top)
        }
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView()
                .environment(settingsData)
        }
        
        MenuBarExtra("SpotCalc Menu Bar", systemImage: "function") {
            MenuBarView(delegate: appDelegate)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            self.window = window
            
            window.setContentSize(.init(width: 600, height: 400))
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
            window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
            window.styleMask.insert([.resizable, .fullSizeContentView])
            window.invalidateShadow()
            window.makeKeyAndOrderFront(nil)
            
            registerHotkey()
            registerSpaceChangeMonitor()
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
    
    func registerSpaceChangeMonitor() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: OperationQueue.main) { notification in
            self.hideWindow()
        }
    }
    
    func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideWindow() {
        window.orderOut(nil)
    }
    
    func centerWindow() {
        if let window = NSApplication.shared.windows.first {
            window.setContentSize(.init(width: 600, height: 400))
            window.center()
        }
    }

    func toggleWindow() {
        if window.isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
}

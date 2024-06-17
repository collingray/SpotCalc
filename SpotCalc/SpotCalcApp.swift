@preconcurrency import AppKit
import SwiftUI

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
            window.styleMask = [.resizable, .fullSizeContentView]
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
    
    @preconcurrency let registerHotkeyOptions: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]

    func registerHotkey() {
        let trusted = AXIsProcessTrustedWithOptions(registerHotkeyOptions)
        
        guard trusted else {
            print("App is not trusted for accessibility.")
            return
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if self.checkToggleEvent(event: event) {
                Task {
                    await AppDelegate.toggleWindow()
                }
            }
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.checkToggleEvent(event: event) {
                Task {
                    await AppDelegate.toggleWindow()
                }
                return nil
            }
            
            return event
        }
    }
    
    func registerSpaceChangeMonitor() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: OperationQueue.main) { notification in
            Task {
                await AppDelegate.hideWindow()
            }
        }
    }
    
    static func showWindow() async {
        if let window = await NSApp.windows.first {
            await window.makeKeyAndOrderFront(nil)
            await NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    static func hideWindow() async {
        if let window = await NSApp.windows.first {
            await window.orderOut(nil)
        }
    }
    
    static func centerWindow() async {
        if let window = await NSApp.windows.first {
            await window.setContentSize(.init(width: 600, height: 400))
            await window.center()
        }
    }

    static func toggleWindow() async {
        if let window = await NSApp.windows.first {
            if await window.isVisible {
                await AppDelegate.hideWindow()
            } else {
                await AppDelegate.showWindow()
            }
        }
    }
}

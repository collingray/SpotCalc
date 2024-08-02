//
//  ShortcutsSettingsView.swift
//  MinCalc
//
//  Created by Collin Gray on 5/26/24.
//

import SwiftUI
import KeyboardShortcuts

struct ShortcutsSettingsView: View {
    @Bindable var shortcutsSettings: ShortcutsSettingsData
    
    var body: some View {
        VStack {
            Form {
                KeyboardShortcuts.Recorder("Toggle main window:", name: .toggleMainWindow)
            }
            
            Button("Restore defaults") {
                KeyboardShortcuts.Name.toggleMainWindow.shortcut = KeyboardShortcuts.Name.toggleMainWindow.defaultShortcut
            }
        }
    }
}

#Preview {
    ShortcutsSettingsView(shortcutsSettings: ShortcutsSettingsData())
}

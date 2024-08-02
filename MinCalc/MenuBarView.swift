//
//  MenuBarView.swift
//  MinCalc
//
//  Created by Collin Gray on 5/25/24.
//

import SwiftUI

struct MenuBarView: View {
    let delegate: AppDelegate
    
    var body: some View {
        Text("MinCalc")
        VStack {
            Section {
                Button("Toggle window") {
                    Task {
                        await AppDelegate.toggleWindow()
                    }
                }.keyboardShortcut(.space, modifiers: [.control, .option, .command])
                
                Button("Center window") {
                    Task {
                        await AppDelegate.centerWindow()
                    }
                }
                
                SettingsLink(label: {
                    Text("Preferences")
                }).keyboardShortcut(",")
            }
            Section {
                Button("Quit MinCalc") {
                    NSApplication.shared.terminate(nil)
                }.keyboardShortcut(KeyEquivalent("q"), modifiers: .command)
            }
        }
    }
}

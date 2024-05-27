//
//  MenuBarView.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/25/24.
//

import SwiftUI

struct MenuBarView: View {
    var body: some View {
        Text("SpotCalc")
        VStack {
            Section {
                
                Button("Toggle window") {
                    
                }.keyboardShortcut(.space, modifiers: [.control, .option, .command])
                Button("Center window") {
                    
                }
                
                SettingsLink(label: {
                    Text("Preferences")
                }).keyboardShortcut(",")
            }
            Section {
                Button("Quit SpotCalc") {
                    
                }
            }
        }
    }
}

#Preview {
    MenuBarView()
}

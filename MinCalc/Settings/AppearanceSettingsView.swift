//
//  AppearanceSettingsView.swift
//  MinCalc
//
//  Created by Collin Gray on 5/26/24.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @Bindable var appearanceSettings: AppearanceSettingsData

    let rowLength = 6
        
    var body: some View {
        VStack {
            Section {
                VStack {
                    ForEach(0..<3) { i in
                        let row = appearanceSettings.graphColors[i*rowLength..<(i+1)*rowLength]
                        HStack {
                            ForEach(Array(row.enumerated()), id: \.offset) { j, color in
                                ColorPicker("", selection: $appearanceSettings.graphColors[(i*rowLength)+j])
                            }
                        }
                    }
                }
            } header: {
                Text("Graph colors")
            } footer: {
                Text("Colors will be used from the top left to the bottom right").font(.caption)
            }
            
            HStack {
                Spacer()
                Button("Restore defaults") {
                    appearanceSettings.setDefaults()
                }.buttonStyle(BorderedButtonStyle())
            }
                .padding(3)
            
//          add dark mode toggle
        }
    }
}

#Preview {
    AppearanceSettingsView(appearanceSettings: AppearanceSettingsData())
}

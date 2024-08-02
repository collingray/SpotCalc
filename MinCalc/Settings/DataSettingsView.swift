//
//  DataSettingsView.swift
//  MinCalc
//
//  Created by Collin Gray on 5/26/24.
//

import SwiftUI

struct DataSettingsView: View {
    @Bindable var dataSettings: DataSettingsData
    @State var syncWithiCloud: Bool = false
    
    var body: some View {
        Section {
            Toggle("Sync with iCloud", isOn: $syncWithiCloud)
        } footer: {
            Text("""
                 If enabled, the following data will be automatically synced
                    • Function and variable definitions
                    • Settings
                    • Appearance
                 """)
        }
        
    }
}

#Preview {
    DataSettingsView(dataSettings: DataSettingsData())
}

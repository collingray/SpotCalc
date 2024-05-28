//
//  GeneralSettingsView.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/26/24.
//

import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var generalSettings: GeneralSettingsData
    
    var body: some View {
        VStack {
            Toggle("Launch on startup", isOn: $generalSettings.launchOnStartup)
        }
    }
}

#Preview {
    GeneralSettingsView(generalSettings: GeneralSettingsData())
}

//
//  SettingsView.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/25/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(SettingsData.self) private var settingsData
    
    private enum Tabs: Hashable {
        case general, shortcuts, appearance, definitions, data
    }
        
    var body: some View {
        TabView {
            GeneralSettingsView(generalSettings: settingsData.general)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            ShortcutsSettingsView(shortcutsSettings: settingsData.shortcuts)
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
                .tag(Tabs.shortcuts)
            AppearanceSettingsView(appearanceSettings: settingsData.appearance)
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
                .tag(Tabs.appearance)
            DefinitionsSettingsView(definitionsSettings: settingsData.definitions)
                .tabItem {
                    Label("Definitions", systemImage: "function")
                }
                .tag(Tabs.definitions)
            DataSettingsView(dataSettings: settingsData.data)
                .tabItem {
                    Label("Data", systemImage: "externaldrive")
                }
                .tag(Tabs.data)
            
        }.labelStyle(.titleAndIcon)
            .frame(width: 400, alignment: .leading)
            .padding()
    }
}

extension Binding {
    func isNotNil<T>() -> Binding<Bool> where Value == T? {
        Binding<Bool>(
            get: { self.wrappedValue != nil },
            set: { newValue in
                if !newValue {
                    self.wrappedValue = nil
                }
            }
        )
    }
    
    func contains<T: Equatable>(_ value: T) -> Binding<Bool> where Value == T?{
        Binding<Bool>(
            get: { self.wrappedValue == value },
            set: { newValue in
                if !newValue {
                    self.wrappedValue = nil
                }
            }
        )
    }
}

#Preview {
    SettingsView()
        .environment(SettingsData())
}


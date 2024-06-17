//
//  SettingsModel.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/27/24.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
class SettingsData {
    var general: GeneralSettingsData
    var shortcuts: ShortcutsSettingsData
    var appearance: AppearanceSettingsData
    var definitions: DefinitionsSettingsData
    var data: DataSettingsData
    
    init(general: GeneralSettingsData, shortcuts: ShortcutsSettingsData, appearance: AppearanceSettingsData, definitions: DefinitionsSettingsData, data: DataSettingsData) {
        self.general = general
        self.shortcuts = shortcuts
        self.appearance = appearance
        self.definitions = definitions
        self.data = data
    }
    
    init() {
        self.general = GeneralSettingsData()
        self.shortcuts = ShortcutsSettingsData()
        self.appearance = AppearanceSettingsData()
        self.definitions = DefinitionsSettingsData()
        self.data = DataSettingsData()
    }
}

@Observable
class GeneralSettingsData {
    var launchOnStartup: Bool
    
    init(launchOnStartup: Bool = true) {
        self.launchOnStartup = launchOnStartup
    }
}

@Observable
class ShortcutsSettingsData {
    var enableGlobalHotkey: Bool
    
    init(enableGlobalHotkey: Bool = true) {
        self.enableGlobalHotkey = enableGlobalHotkey
    }
}

@Observable
class AppearanceSettingsData {
    var graphColors: [Color]
    
    init(graphColors: [Color]) {
        self.graphColors = graphColors
    }
    
    init() {
        self.graphColors = AppearanceSettingsData.defaultGraphColors
    }
    
    func setDefaults() {
        self.graphColors = AppearanceSettingsData.defaultGraphColors
    }
    
    static let defaultGraphColors: [Color] = [
        .red,
        .blue,
        .green,
        .black,
        .yellow,
        .orange,
        .green,
        .black,
        .yellow,
        .orange,
        .green,
        .black,
        .yellow,
        .yellow,
        .orange,
        .green,
        .yellow,
        .orange
    ]
}

@Observable
class DefinitionsSettingsData {
    var functionDefinitions: [String: any Expression]
    var variableDefinitions: [String: any Expression]

    init(functionDefinitions: [String : any Expression] = [:], variableDefinitions: [String : any Expression] = [:]) {
        self.functionDefinitions = functionDefinitions
        self.variableDefinitions = variableDefinitions
    }
}

@Observable
class DataSettingsData {
    var syncWithiCloud: Bool
    
    init(syncWithiCloud: Bool = false) {
        self.syncWithiCloud = syncWithiCloud
    }
}

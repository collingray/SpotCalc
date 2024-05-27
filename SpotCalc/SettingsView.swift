//
//  SettingsView.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/25/24.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, shortcuts, appearance, definitions, data
    }
        
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
                .tag(Tabs.shortcuts)
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
                .tag(Tabs.appearance)
            DefinitionsSettingsView()
                .tabItem {
                    Label("Definitions", systemImage: "function")
                }
                .tag(Tabs.definitions)
            DataSettingsView()
                .tabItem {
                    Label("Data", systemImage: "externaldrive")
                }
                .tag(Tabs.data)
            
        }.labelStyle(.titleAndIcon)
            .frame(width: 400, alignment: .leading)
            .padding()
    }
}

struct GeneralSettingsView: View {
    @State var launchOnStartup: Bool = true
    
    var body: some View {
        VStack {
            Toggle("Launch on startup", isOn: $launchOnStartup)
        }
    }
}

struct ShortcutsSettingsView: View {
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

struct AppearanceSettingsView: View {
    @State var colors: [Color] = [
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
    
    let rowLength = 6
        
    var body: some View {
        VStack {
            
            Section {
                VStack {
                    ForEach(0..<3) { i in
                        let row = colors[i*rowLength..<(i+1)*rowLength]
                        HStack {
                            ForEach(Array(row.enumerated()), id: \.offset) { j, color in
                                ColorPicker("", selection: $colors[(i*rowLength)+j])
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
                    print("todo")
                }.buttonStyle(BorderedButtonStyle())
            }
                .padding(3)
        }
    }
}

struct FnDefinition: Identifiable {
    let name: String
    let definition: String
    let id: UUID = UUID()
}

struct DefinitionsSettingsView: View {
    @State var functionDefinitions: [FnDefinition] = [
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
    ]
    
    @State var selectedDefinitions: Set<UUID> = Set()
    @State var editingDefinition: UUID? = nil
    @State var creatingDefinition: Bool = false
    @State var deleteConfirmation: Bool = false
    @State var suppressDeleteConfirmation: Bool = false
    
    var body: some View {
        VStack {
            Table(functionDefinitions, selection: $selectedDefinitions) {
                TableColumn("Function") { def in
                    Button(action: { editDefinition(id: def.id) }, label: {
                        Text(def.name)
                    })
                }.width(min: 20, ideal: 80, max: 250)
                
                TableColumn("Definition") { def in
                    Button(action: { editDefinition(id: def.id) }, label: {
                        Text(def.definition)
                    })
                }.width(min: 20, ideal: 350, max: 500)
            }.tableStyle(.bordered)
            
            HStack {
                Button(action: createDefinition, label: {
                    Image(systemName: "plus")
                        .frame(width: 12.5, height: 12.5)
                })
                Button(action: {
                    if suppressDeleteConfirmation {
                        deleteDefinitions()
                    } else {
                        deleteConfirmation = true
                    }
                }, label: {
                    Image(systemName: "minus")
                        .frame(width: 12.5, height: 12.5)
                })
                    .disabled(selectedDefinitions.isEmpty)
                    .confirmationDialog("Delete \(selectedDefinitions.count) definitions", isPresented: $deleteConfirmation) {
                        Button("Delete", role: .destructive) {
                            deleteDefinitions()
                        }
                    }
                    .dialogIcon(Image(systemName: "trash.circle.fill"))
                    .dialogSuppressionToggle(isSuppressed: $suppressDeleteConfirmation)
                Spacer()
                Button("Restore defaults") {
                    print("todo")
                }.buttonStyle(BorderedButtonStyle())
            }.buttonStyle(BorderlessButtonStyle())
                .padding(3)
        }.frame(height: 300).sheet(isPresented: $editingDefinition.isNotNil(), content: {
            NavigationStack {
                EditingSheet(functionDefinitions: $functionDefinitions, editingDefinition: $editingDefinition, isNew: $creatingDefinition)
            }
        })
    }
    
    func editDefinition(id: UUID) {
        creatingDefinition = false
        editingDefinition = id
    }
    
    func createDefinition() {
        let newDef = FnDefinition(name: "f(x)", definition: "x")
        functionDefinitions.append(newDef)
        creatingDefinition = true
        editingDefinition = newDef.id
    }
    
    func deleteDefinitions() {
        
        functionDefinitions.removeAll { def in
            selectedDefinitions.contains(def.id)
        }
        
        selectedDefinitions.removeAll()
    }
}

struct EditingSheet: View {
    @Binding var functionDefinitions: [FnDefinition]
    @Binding var editingDefinition: UUID?
    @Binding var isNew: Bool
    
    @State var functionName: String = ""
    @State var functionDefinition: String = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Function", text: $functionName, prompt: Text("f(x)"))
                TextField("Definition", text: $functionDefinition, prompt: Text("x"))
            }
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    if let id = editingDefinition, isNew {
                        functionDefinitions.removeAll(where: {$0.id == id})
                    }
                    editingDefinition = nil
                }.buttonStyle(BorderedButtonStyle())
                
                Button("Submit") {
                    if let id = editingDefinition, !functionName.isEmpty && !functionDefinition.isEmpty {
                        let funcIndex = functionDefinitions.firstIndex(where: {$0.id == id})!
                        let newFunc = FnDefinition(name: functionName, definition: functionDefinition)
                        functionDefinitions[funcIndex] = newFunc
                    }
                    
                    editingDefinition = nil
                }.buttonStyle(BorderedProminentButtonStyle())
            }
        }.navigationTitle(isNew ? Text("Create definition") : Text("Edit definition"))
            .onAppear {
                if let id = editingDefinition, !isNew {
                    let def = functionDefinitions.first(where: {$0.id == id})!
                    functionName = def.name
                    functionDefinition = def.definition
                }
            }
            .frame(width: 350, height: 150)
            .padding()
    }
    
}

struct DataSettingsView: View {
    var body: some View {
        Text("aoeu")
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
}

#Preview {
    SettingsView()
}


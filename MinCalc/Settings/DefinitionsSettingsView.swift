//
//  DefinitionsSettingsView.swift
//  MinCalc
//
//  Created by Collin Gray on 5/26/24.
//

import SwiftUI

struct FnDefinition: Identifiable {
    var name: String
    var definition: String
    let id: UUID = UUID()
    
    var funcErrorMessage: String? {
        if name == "x" {
            return "Some error"
        } else {
            return nil
        }
    }
    
    var funcErrorShown: Bool = false
    
    var defErrorMessage: String? {
        if name != "x" {
            return "Some error"
        } else {
            return nil
        }
    }
    
    var defErrorShown: Bool = false
}

struct DefinitionsSettingsView: View {
    @Bindable var definitionsSettings: DefinitionsSettingsData
    
    enum Tabs {
        case functions, variables
    }
    
    var body: some View {
        TabView {
            FunctionDefinitionsView().tabItem { Text("Functions") }.tag(Tabs.functions)
            Text("Tab Content 2").tabItem { Text("Variables") }.tag(Tabs.variables)
        }
    }
}

struct FunctionDefinitionsView: View {
    @State var functionDefinitions: [FnDefinition] = [
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
        FnDefinition(name: "f(x)", definition: "x"),
    ]
    
    @State var selectedDefinitions: Set<UUID> = Set()
    @State var editingDefinition: UUID? = nil
    @State var creatingDefinition: Bool = false
    @State var deleteConfirmation: Bool = false
    @State var suppressDeleteConfirmation: Bool = false
    @FocusState var focusedDefinition: UUID?
    
    @State var displayedErrorPopover: UUID? = nil
    
    var body: some View {
        VStack {
            Table($functionDefinitions, selection: $selectedDefinitions) {
                TableColumn("Function") { def in
                    ZStack {
                        TextField("Function name", text: def.name)
                            .focused($focusedDefinition, equals: def.id)
                        
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                displayedErrorPopover = def.id
                            }, label: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
//                                    .popover(isPresented: $displayedErrorPopover.contains(def.id), content: {
//                                        Text(def.$defErrorMessage.wrappedValue ?? "")
//                                    })
                            })
                        }
                    }
                }.width(min: 20, ideal: 80, max: 250)
                
                TableColumn("Definition") { def in
                    TextField("Function definition", text: def.definition)
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
        }.frame(height: 300)
    }
    
    func createDefinition() {
        let newDef = FnDefinition(name: "f(x)", definition: "x")
        functionDefinitions.append(newDef)
        selectedDefinitions.removeAll()
        selectedDefinitions.insert(newDef.id)
        focusedDefinition = newDef.id
    }
    
    func deleteDefinitions() {
        
        functionDefinitions.removeAll { def in
            selectedDefinitions.contains(def.id)
        }
        
        selectedDefinitions.removeAll()
    }
}

//struct EditingSheet: View {
//    @Binding var functionDefinitions: [FnDefinition]
//    @Binding var editingDefinition: UUID?
//    @Binding var isNew: Bool
//    
//    @State var functionName: String = ""
//    @State var functionDefinition: String = ""
//    
//    var body: some View {
//        VStack {
//            HStack {
//                TextField("Function", text: $functionName, prompt: Text("f(x)"))
//                TextField("Definition", text: $functionDefinition, prompt: Text("x"))
//            }
//            
//            HStack {
//                Spacer()
//                
//                Button("Cancel") {
//                    if let id = editingDefinition, isNew {
//                        functionDefinitions.removeAll(where: {$0.id == id})
//                    }
//                    editingDefinition = nil
//                }.buttonStyle(BorderedButtonStyle())
//                
//                Button("Submit") {
//                    if let id = editingDefinition, !functionName.isEmpty && !functionDefinition.isEmpty {
//                        let funcIndex = functionDefinitions.firstIndex(where: {$0.id == id})!
//                        let newFunc = FnDefinition(name: functionName, definition: functionDefinition)
//                        functionDefinitions[funcIndex] = newFunc
//                    }
//                    
//                    editingDefinition = nil
//                }.buttonStyle(BorderedProminentButtonStyle())
//            }
//        }.navigationTitle(isNew ? Text("Create definition") : Text("Edit definition"))
//            .onAppear {
//                if let id = editingDefinition, !isNew {
//                    let def = functionDefinitions.first(where: {$0.id == id})!
//                    functionName = def.name
//                    functionDefinition = def.definition
//                }
//            }
//            .frame(width: 350, height: 150)
//            .padding()
//    }
//}

#Preview {
    DefinitionsSettingsView(definitionsSettings: DefinitionsSettingsData())
}

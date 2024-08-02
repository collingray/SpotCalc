//
//  ContentView.swift
//  MinCalc
//
//  Created by Collin Gray on 5/19/24.
//

import SwiftUI

struct ContentView: View {
    @State private var data = ExpressionData()
    
    var body: some View {
        
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                MainView()
            }.frame(width: 600)
            if data.graphVisible {
                GraphPanelView()
                    .frame(width: 400)
                    .transition(.move(edge: .trailing))
                    .zIndex(-1) // Necessary to ensure overdrawn graph points do not interfere with equation button hitboxes
            }
        }
        .environment(data)
        .background(VisualEffectView(material: .toolTip, blendingMode: .withinWindow))
    }
}

#Preview {
    ContentView()
}

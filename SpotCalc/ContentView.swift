//
//  ContentView.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/19/24.
//

import SwiftUI

struct ContentView: View {
    @State private var expressions: [ExpressionData] = []
    
    var graphVisible: Bool {
        expressions.contains { expression in
            expression.isGraphed
        }
    }
    
    var body: some View {
        
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                MainView(expressions: $expressions)
            }.frame(width: 600)
            if graphVisible {
                GraphPanelView(expressions: $expressions)
                    .frame(width: 400)
                    .transition(.move(edge: .trailing))
            }
        }
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
    }
}

#Preview {
    ContentView()
}

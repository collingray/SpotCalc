//
//  GraphPanelView.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/19/24.
//

import SwiftUI
import Charts
import BigDecimal

struct GraphPanelView: View {
    @Environment(ExpressionData.self) var data: ExpressionData
    
    @State var xMin: Double = -10
    @State var xMax: Double = 10
    @State var yMin: Double = -10
    @State var yMax: Double = 10
    
    @State var xScale: GraphScale = .linear
    @State var yScale: GraphScale = .linear
    
    var functions: [(Int, ([Float]) -> Result<[Float], ExpressionError>, Color)] {
        return data.expressions.filter { expr in
            expr.isGraphed && expr.parameters?.count == 1
        }.map { expr in
            let varName: String = expr.parameters!.first!
            
            let f: ([Float]) -> Result<[Float], ExpressionError> = { data in
                let l = List(data: data.map({ d in
                    Literal(val: BigDecimal(Double(d)))
                }))
                
                if let ast = expr.ast {
                    return ast.batch_eval([varName : l], [:])
                } else {
                    return .failure(.genericError(msg: "Expression failed to parse, cannot graph"))
                }
            }
            
            return (expr.num, f, expr.graphColor ?? .blue)
        }
    }
    
    var steps: Double {
        1000.0 * pow(0.95, Double(functions.count))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GraphView(functions: functions, steps: steps, xMin: $xMin, xMax: $xMax, yMin: $yMin, yMax: $yMax, xScale: $xScale, yScale: $yScale)
                .clipped()
                .padding()
            
            HStack {
                VStack {
                    Picker("x", selection: $xScale) {
                        Image(systemName: "line.diagonal").tag(GraphScale.linear)
                        Image(systemName: "function").tag(GraphScale.log)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    .fixedSize()
                    
                    Text("x")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }
                
                VStack {
                    Picker("y", selection: $yScale) {
                        Image(systemName: "line.diagonal").tag(GraphScale.linear)
                        Image(systemName: "function").tag(GraphScale.log)
                    }
                    .labelsHidden()
                    .pickerStyle(SegmentedPickerStyle())
                    .fixedSize()
                    Text("y")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Button("Center", systemImage: "dot.scope") {
                    let width = xMax - xMin
                    let height = yMax - yMin
                    
                    xMin = -width/2
                    xMax = width/2
                    yMin = -height/2
                    yMax = height/2
                }
                .labelStyle(.iconOnly)
                .buttonStyle(BorderlessButtonStyle())
            }
                .padding()
                .textFieldStyle(.plain)
                .font(.title)
                .frame(height: 50.0, alignment: .center)
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.secondary), alignment: .top)
        }.overlay(Rectangle().frame(width: 1, height: nil, alignment: .leading).foregroundColor(Color.gray), alignment: .leading)
    }
}

enum GraphScale {
    case linear
    case log
    
    func scaleType() -> ScaleType {
        switch self {
        case .linear: return ScaleType.linear
        case .log: return ScaleType.log
        }
    }
}

//#Preview {
//    GraphPanelView()
//}

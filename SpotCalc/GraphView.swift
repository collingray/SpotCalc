//
//  GraphView.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/19/24.
//

import SwiftUI
import Charts
import AppKit

struct GraphView: View {
    let functions: [(Int, (Float) -> Float, Color)]
    let steps: Double
    
    @Binding var xMin: Double
    @Binding var xMax: Double
    @Binding var yMin: Double
    @Binding var yMax: Double
    @Binding var xScale: GraphScale
    @Binding var yScale: GraphScale
    
    static let overdraw: Double = 2.0
    
    @State var dxMin: Double = 0
    @State var dxMax: Double = 0
    @State var dyMin: Double = 0
    @State var dyMax: Double = 0
    
    var xDomain: some ScaleDomain {
        switch xScale {
        case .linear: xMin+dxMin...xMax+dxMax
        case .log: pow(10, xMin+dxMin)...pow(10, xMax+dxMax)
        }
    }
    
    var yDomain: some ScaleDomain {
        switch yScale {
        case .linear: yMin+dyMin...yMax+dyMax
        case .log: pow(10, yMin+dyMin)...pow(10, yMax+dyMax)
        }
    }
    
    var x_points: [Double] {
        let overdraw_width = GraphView.overdraw * (xMax-xMin) / 2
        let points = Array(stride(from: xMin - overdraw_width, through: xMax + overdraw_width, by: (xMax - xMin) / steps))
        
        switch xScale {
        case .linear: return points
        case .log: return points.map({pow(10, $0)})
        }
    }
    
    var plotData: [(Int, Float, Float, Color)] {
        x_points.flatMap { x in
            
            functions.map { i, f, c in
                (i, Float(x), f(Float(x)), c)
            }
        }
    }
        
    var body: some View {
        GeometryReader { proxy in
            Chart(plotData, id: \.self.0) {
                LineMark(
                    x: .value("x", $0.1),
                    y: .value("y", $0.2),
                    series: .value("num", $0.0)
                ).foregroundStyle($0.3)
            }
            .chartXScale(domain: xDomain, type: xScale.scaleType())
            .chartYScale(domain: yDomain, type: yScale.scaleType())
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let magnification = Double(value.magnification)
                        let offset = value.startAnchor
                                                
                        if magnification != 0.0 {
                            let dx = (magnification - 1.0) * (xMax - xMin)
                            let dy = (magnification - 1.0) * (yMax - yMin)
                            
                            dxMin = Double(offset.x) * dx
                            dxMax = (Double(offset.x) - 1.0) * dx
                            print(dx, dxMin, dxMax)
                            dyMin = (1.0 - Double(offset.y)) * dy
                            dyMax = -Double(offset.y) * dy
                        }
                    }.onEnded { val in
                        print(val.magnification)
                        
                        xMin += dxMin
                        xMax += dxMax
                        yMin += dyMin
                        yMax += dyMax
                        
                        dxMin = 0
                        dxMax = 0
                        dyMin = 0
                        dyMax = 0
                    }
            ).highPriorityGesture(
                DragGesture()
                    .onChanged { value in
                        let dx = -Double(value.translation.width / proxy.size.width) * (xMax - xMin)
                        let dy = Double(value.translation.height / proxy.size.height) * (yMax - yMin)
                        dxMin = dx
                        dxMax = dx
                        dyMin = dy
                        dyMax = dy
                    }
                    .onEnded { value in
                        xMin += dxMin
                        xMax += dxMax
                        yMin += dyMin
                        yMax += dyMax
                        
                        dxMin = 0
                        dxMax = 0
                        dyMin = 0
                        dyMax = 0
                    }
            ).onAppear {
                yMin = xMin * Double(proxy.size.height / proxy.size.width)
                yMax = xMax * Double(proxy.size.height / proxy.size.width)
            }.onChange(of: proxy.size) { oldValue, newValue in
                
                let percentChange = Double(newValue.height / oldValue.height) - 1
                
                let yHeight = yMax - yMin
                yMin -= percentChange * yHeight / 2
                yMax += percentChange * yHeight / 2
            }
        }
    }
}

//#Preview {
//    GraphPanelView()
//}

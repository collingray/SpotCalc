//
//  Expression.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/19/24.
//

import Foundation
import SwiftUI

struct ExpressionData {
    let num: Int
    var expressionString: String
    var ast: Expression?
    var latexString: String?
    var displayString: String
    var displayValue: String?
    var variables: Set<String>
    var graphColor: Color?
    
    var isGraphed: Bool {
        return graphColor != nil
    }
    
    static var total_count = 0
    static let possible_colors: [Color] = [
        .pink,
        .brown,
        .yellow,
        .cyan,
        .gray,
        .indigo,
        .mint,
        .purple,
        .orange,
        .green,
        .blue,
        .red,
    ]
    static var available_colors: [Color] = possible_colors
    
    init(_ expression: String) throws {
        num = ExpressionData.total_count
        ExpressionData.total_count += 1
        expressionString = expression
        let parser = Parser(expression: expression)
        ast = try parser.parse()
        latexString = ast?.renderLatex()
        displayString = latexString ?? expression
        variables = ast?.getVariables() ?? Set()
        displayValue = ast?.eval([:])?.description
    }
    
    mutating func updateExpression(_ newExpression: String) {
        if newExpression != expressionString {
            expressionString = newExpression
            let parser = Parser(expression: expressionString)
            ast = try? parser.parse()
            latexString = ast?.renderLatex()
            displayString = latexString ?? expressionString
            variables = ast?.getVariables() ?? Set()
            displayValue = ast?.eval([:])?.description
        }
    }
    
    mutating func enableGraph() {
        if let color = ExpressionData.available_colors.popLast() {
            graphColor = color
        }
    }
    
    mutating func disableGraph() {
        if let color = graphColor {
            ExpressionData.available_colors.append(color)
            graphColor = nil
        }
    }
}

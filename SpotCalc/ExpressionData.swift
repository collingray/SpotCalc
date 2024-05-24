//
//  Expression.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/19/24.
//

import Foundation
import SwiftUI
import BigDecimal

@Observable 
class ExpressionData {
    var expressions: [ParsedExpression]
    
    init(_ expressions: [ParsedExpression] = []) {
        self.expressions = expressions
    }
    
    var graphVisible: Bool {
        expressions.contains { expression in
            expression.isGraphed
        }
    }
    
    var count: Int {
        expressions.count
    }
    
    var variables: [String : BigDecimal] {
        let vars = self.expressions.compactMap { expression in
            if let val = expression.value {
                return ("x\(expression.num)", val)
            } else {
                return nil
            }
        }
        
        return Dictionary(uniqueKeysWithValues: vars)
    }
    
    var functions: [String : ([Expression]) -> Expression?] {
        let funcs = self.expressions.compactMap { expression in
            if let f = expression.function {
                return ("f\(expression.num)", f)
            } else {
                return nil
            }
        }
        
        return Dictionary(uniqueKeysWithValues: funcs)
    }
}

@Observable
class ParsedExpression {
    let num: Int
    
    var ast: Expression?
    
    var expressionString: String
    var displayString: String
    var value: BigDecimal?
    
    var parameters: [String]?
    var function: (([Expression]) -> Expression?)?
    
    var graphColor: Color?
    var isGraphed: Bool {
        graphColor != nil
    }
    
    var isError: Bool {
        ast == nil
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
        num = ParsedExpression.total_count
        ParsedExpression.total_count += 1
        expressionString = expression
        let parser = Parser(expression: expression)
        let parsed = try? parser.parse()
        ast = parsed
        
        let latexString = parsed?.renderLatex()
        displayString = latexString ?? expression
        value = ast?.eval([:], [:])
        
        if let (params, f) = ast?.makeFunction([:]), params.count > 0 {
            parameters = params
            function = f
        } else {
            parameters = nil
            function = nil
        }
        
        if let tree = ast?.printTree() {
            print(tree)
        }
    }
    
    func updateExpression(_ newExpression: String) {
        if newExpression != expressionString {
            expressionString = newExpression
            let parser = Parser(expression: expressionString)
            ast = try? parser.parse()
            
            let latexString = ast?.renderLatex()
            displayString = latexString ?? expressionString
            value = ast?.eval([:], [:])
            
            if let (params, f) = ast?.makeFunction([:]), params.count > 0 {
                parameters = params
                function = f
            } else {
                parameters = nil
                function = nil
            }
            
            if let tree = ast?.printTree() {
                print(tree)
            }
        }
    }
    
    func enableGraph() {
        if let color = ParsedExpression.available_colors.popLast() {
            graphColor = color
        }
    }
    
    func disableGraph() {
        if let color = graphColor {
            ParsedExpression.available_colors.append(color)
            graphColor = nil
        }
    }
}

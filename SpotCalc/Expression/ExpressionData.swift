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
    var expressions: [DisplayExpression]
    
    init(_ expressions: [DisplayExpression] = []) {
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
            if let val = expression.eval([:], functions: [:]), let name = expression.name {
                return (name, val)
            } else {
                return nil
            }
        }
        
        return Dictionary(uniqueKeysWithValues: vars)
    }
    
    var functions: [String : ([Expression]) -> Expression?] {
        let funcs = self.expressions.compactMap { expression in
            if let f = expression.function, let name = expression.name {
                return (name, f)
            } else {
                return nil
            }
        }
        
        return Dictionary(uniqueKeysWithValues: funcs)
    }
}

@Observable
class DisplayExpression: ParsedExpression {
    var graphColor: Color?
    
    var isGraphed: Bool {
        graphColor != nil
    }
    
    var definitionLatex: String? {
        if let name = name {
            if let params = parameters {
                return "\(name)(\(params.joined(separator: ","))) ="
            } else {
                return "\(name) ="
            }
        } else {
            return nil
        }
    }
    
    var bodyLatex: String? {
        if let expression = ast as? Definition? {
            return expression?.body.renderLatex()
        } else {
            return ast?.renderLatex()
        }
    }
    
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
    
    func enableGraph() {
        if let color = DisplayExpression.available_colors.popLast() {
            graphColor = color
        }
    }
    
    func disableGraph() {
        if let color = graphColor {
            DisplayExpression.available_colors.append(color)
            graphColor = nil
        }
    }
}

@Observable
class ParsedExpression: Identifiable {
    let id: Int
    
    var ast: Expression?
    var expressionString: String
    var parameters: [String]?
    var function: (([Expression]) -> Expression?)?
    
    var name: String? {
        if isError {
            return nil
        } else {
            if let ast = ast as? Definition {
                return ast.name
            } else {
                return "\(isFunc ? "f" : "x")_{\(id.description)}"
            }
        }
    }
    
    var isError: Bool {
        ast == nil
    }
    
    var isFunc: Bool {
        parameters != nil
    }
    
    static var total_count = 0
    
    init(_ expression: String, globalVariables: [String : Expression] = [:]) throws {
        id = ParsedExpression.total_count
        ParsedExpression.total_count += 1
        
        expressionString = expression
        let parser = Parser(expression: expression)
        ast = try? parser.parse()
        
        if let (params, f) = ast?.makeFunction(globalVariables), params.count > 0 {
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
    
    func updateExpression(_ newExpression: String, globalVariables: [String : Expression] = [:]) {
        if newExpression != expressionString {
            expressionString = newExpression
            let parser = Parser(expression: expressionString)
            ast = try? parser.parse()
            
            if let (params, f) = ast?.makeFunction(globalVariables), params.count > 0 {
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
    
    func eval(_ variables: [String: Expression], functions: [String : ([Expression]) -> Expression?]) -> BigDecimal? {
        return ast?.eval(variables, functions)
    }
}

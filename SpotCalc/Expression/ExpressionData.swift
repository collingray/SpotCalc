//
//  Expression.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/19/24.
//

import Foundation
import SwiftUI
import BigDecimal
import Combine

@Observable 
class ExpressionData {
    private(set) var expressions: [DisplayExpression]
    
    var variables: [String : Expression] = [:]
    var functions: [String : ([Expression]) -> Expression?] = [:]
    var values: [Int : BigDecimal] = [:]
    var overwritten: Set<Int> = Set()
    
    var externalVariables: [String : Expression]
    var externalFunctions: [String : ([Expression]) -> Expression?]
    
    init(_ exprs: [DisplayExpression] = [], _ externalVariables: [String : Expression] = [:], _ externalFunctions: [String : ([Expression]) -> Expression?] = [:]) {
        self.expressions = exprs
        
        self.externalVariables = externalVariables
        self.externalFunctions = externalFunctions

        updateData()
    }
        
    var graphVisible: Bool {
        expressions.contains { expression in
            expression.isGraphed
        }
    }
    
    var count: Int {
        expressions.count
    }
    
    func updateData() {
        var vars: [String : Expression] = externalVariables
        var funcs: [String : ([Expression]) -> Expression?] = externalFunctions
        
        values = [:]
        overwritten = Set()
        
        for expr in expressions {
            if let ast = expr.ast {
                if let value = expr.eval(vars, funcs) {
                    values.updateValue(value, forKey: expr.id)
                }
                
                if let name = expr.name {
                    if let function = expr.function, expr.isFunc {
                        if funcs.updateValue(function, forKey: name) != nil {
                            if let id = expressions.first(where: { expr in
                                expr.name == name && !overwritten.contains(expr.id)
                            })?.id {
                                overwritten.insert(id)
                            }
                        }
                    } else {
                        if vars.updateValue(ast, forKey: name) != nil {
                            if let id = expressions.first(where: { expr in
                                expr.name == name && !overwritten.contains(expr.id)
                            })?.id {
                                overwritten.insert(id)
                            }
                        }
                    }
                }
            }
        }
        
        variables = vars
        functions = funcs
        
        
        
        print(variables)
        print(functions)
        print(values)
        print(overwritten)
    }
    
    func addExpression(_ expression: String) throws {
        let expr = try DisplayExpression(expression, variables: variables)
        expressions.append(expr)
        
        updateData()
    }
    
    func updateExpression(id: Int, _ newExpression: String) {
        if let expr = expressions.first(where: {$0.id == id}) {
            expr.updateExpression(newExpression, variables: variables)
        }
        
        updateData()
    }
    
    func removeExpression(id: Int) {
        if let i = expressions.firstIndex(where: {$0.id == id}) {
            expressions.remove(at: i)
        }
        
        updateData()
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
            if let ast = ast as? Definition {
                return "\(ast.renderLatexDefinition()) ="
            } else if let params = parameters {
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
    
    init(_ expression: String, variables: [String : Expression] = [:]) throws {
        id = ParsedExpression.total_count
        ParsedExpression.total_count += 1
        
        expressionString = expression
        let parser = Parser(expression: expression)
        ast = try? parser.parse()
        
        if let (params, f) = ast?.makeFunction(variables), params.count > 0 {
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
    
    func updateExpression(_ newExpression: String, variables: [String : Expression] = [:]) {
        if newExpression != expressionString {
            expressionString = newExpression
            let parser = Parser(expression: expressionString)
            ast = try? parser.parse()
            
            if let (params, f) = ast?.makeFunction(variables), params.count > 0 {
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
    
    func eval(_ variables: [String: Expression], _ functions: [String : ([Expression]) -> Expression?]) -> BigDecimal? {
        return ast?.eval(variables, functions)
    }
}

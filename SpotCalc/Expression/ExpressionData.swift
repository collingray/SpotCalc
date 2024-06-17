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
    
    var variables: [String : any Expression] = [:]
    var functions: [String : ([any Expression]) -> (any Expression)?] = [:]
    var values: [Int : BigDecimal] = [:]
    var overwritten: Set<Int> = Set()
    
    var externalVariables: [String : any Expression]
    var externalFunctions: [String : ([any Expression]) -> (any Expression)?]
    
    // total number of expressions that have been added, including expressions that have been deleted
    var expression_count = 0
    
    let graph_colors: [Color] = [
        .red,        
        .blue,
        .green,
        .orange,
        .purple,
        .mint,
        .indigo,
        .gray,
        .cyan,
        .yellow,
        .brown,
        .pink,
    ]
    
    init(_ exprs: [DisplayExpression] = [], _ externalVariables: [String : any Expression] = [:], _ externalFunctions: [String : ([any Expression]) -> (any Expression)?] = [:]) {
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
        var vars: [String : any Expression] = externalVariables
        var funcs: [String : ([any Expression]) -> (any Expression)?] = externalFunctions
        
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
    }
    
    func addExpression(_ expression: String) throws {
        let expr = try DisplayExpression(expression, id: expression_count, variables: variables)
        expressions.append(expr)
        expression_count += 1
        
        updateData()
    }
    
    func updateExpression(id: Int, _ newExpression: String) {
        if let expr = expressions.first(where: {$0.id == id}) {
            expr.updateExpression(newExpression, variables: variables)
            
            if !expr.isGraphable {
                expr.disableGraph()
            }
        }
        
        updateData()
    }
    
    func removeExpression(id: Int) {
        if let i = expressions.firstIndex(where: {$0.id == id}) {
            expressions.remove(at: i)
        }
        
        updateData()
    }
    
    func toggleGraph(id: Int) {
        if let i = expressions.firstIndex(where: {$0.id == id}) {
            if expressions[i].isGraphed {
                expressions[i].disableGraph()
            } else {
                // find first color in 'graph_colors' that is not currently used by any graph
                if let color = graph_colors.first(where: { c in
                    !expressions.contains(where: { $0.graphColor == c })
                }) {
                    expressions[i].enableGraph(color)
                }
            }
        }
    }
}

@Observable
class DisplayExpression: ParsedExpression {
    var graphColor: Color?
    
    var isGraphed: Bool {
        graphColor != nil
    }
    
    var isGraphable: Bool {
        if let params = parameters {
            return params.count == 1
        } else {
            return false
        }
    }
    
    var definitionLatex: String? {
        if let name = name {
            if let ast = ast as? any Definition {
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
        if let expression = ast as? (any Definition)? {
            return expression?.body.renderLatex()
        } else {
            return ast?.renderLatex()
        }
    }
    
    func enableGraph(_ color: Color) {
        if isGraphable {
            graphColor = color
        }
    }
    
    func disableGraph() {
        graphColor = nil
    }
}

@Observable
class ParsedExpression: Identifiable {
    let id: Int
    
    var ast: (any Expression)?
    var expressionString: String
    var parameters: [String]?
    var function: (([any Expression]) -> (any Expression)?)?
    
    var name: String? {
        if isError {
            return nil
        } else {
            if let ast = ast as? any Definition {
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
    
    init(_ expression: String, id: Int, variables: [String : any Expression] = [:]) throws {
        self.id = id
        
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
    
    func updateExpression(_ newExpression: String, variables: [String : any Expression] = [:]) {
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
    
    func eval(_ variables: [String: any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        return ast?.eval(variables, functions)
    }
}

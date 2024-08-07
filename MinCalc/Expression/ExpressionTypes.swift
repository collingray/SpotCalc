//
//  ExpressionTypes.swift
//  MinCalc
//
//  Created by Collin Gray on 5/18/24.
//

import Foundation
import BigDecimal
import Accelerate

enum ExpressionError: Error {
    case missingSymbol(type: String, name: String)
    case errorList(errors: [ExpressionError])
    case genericError(msg: String)
}

protocol Expression {
    func apply(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> (any Expression)?
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal?
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError>
    func getVariables() -> [String]
    func getFunctions() -> [String]
    func renderLatex() -> String
    func printTree() -> String
}

extension Expression {
    func makeFunction(_ globalVariables: [String: any Expression]) -> ([String], ([any Expression]) -> (any Expression)?) {
        let inputNames: [String] = self.getVariables().filter { v in
            !globalVariables.contains(where: {$0.key == v})
        }
        
        let function: ([any Expression]) -> (any Expression)? = { (inputExpressions: [any Expression]) -> (any Expression)? in
            if inputExpressions.count != inputNames.count {
                return nil
            }
            let inputs = Dictionary(uniqueKeysWithValues: zip(inputNames, inputExpressions))
            return self.apply(inputs, [:])
        }
        
        return (inputNames, function)
    }
}

protocol UnaryExpression: Expression {
    var x: any Expression { get set }
    
    static var symbol: String { get }
}

extension UnaryExpression {
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        var copy = self
        if let x2 = copy.x.apply(variables, functions) {
            copy.x = x2
        }
        
        return copy
    }
    
    func getVariables() -> [String] {
        return x.getVariables()
    }
    
    func getFunctions() -> [String] {
        return x.getFunctions()
    }
    
    func printTree() -> String {
        return """
        \(Self.symbol)
        └── \(x.printTree().replacingOccurrences(of: "\n", with: "\n    "))
        """
    }
}

protocol BinaryExpression: Expression {
    var x: any Expression { get set }
    var y: any Expression { get set }
    
    static var symbol: String { get }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float]
}

extension BinaryExpression {
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        var copy = self
        if let x2 = copy.x.apply(variables, functions), let y2 = copy.y.apply(variables, functions) {
            copy.x = x2
            copy.y = y2
        }
        
        return copy
    }
    
    func batch_eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let size = max(v1.count, v2.count)
            
            do {
                let v1 = try v1.repeatTo(size)
                let v2 = try v2.repeatTo(size)
                
                return .success(Self._batch_eval(v1: v1, v2: v2))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func getVariables() -> [String] {
        let lhs = x.getVariables()
        let rhs = y.getVariables().filter { !lhs.contains($0) }
        return lhs + rhs
    }
    
    func getFunctions() -> [String] {
        let lhs = x.getFunctions()
        let rhs = y.getFunctions().filter { !lhs.contains($0) }
        return lhs + rhs
    }
    
    func printTree() -> String {
        return """
        \(Self.symbol)
        ├── \(x.printTree().replacingOccurrences(of: "\n", with: "\n|   "))
        └── \(y.printTree().replacingOccurrences(of: "\n", with: "\n    "))
        """
    }
}

protocol NAryExpression: Expression {
    var args: [any Expression] { get set }
    
    static var n: Int { get }
    static var symbol: String { get }
}

extension NAryExpression {
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        let newArgs = args.compactMap { expr in
            expr.apply(variables, functions)
        }
        
        if newArgs.count == args.count {
            var copy = self
            copy.args = newArgs
            return copy
        } else {
            return nil
        }
    }
    
    func getVariables() -> [String] {
        args.flatMap { expr in
            expr.getVariables()
        }
    }
    
    func getFunctions() -> [String] {
        args.flatMap { expr in
            expr.getFunctions()
        }
    }
    
    func printTree() -> String {
        if let last = args.last {
            return """
            \(Self.symbol)
            \(args.dropLast().map{ "├── \($0.printTree().replacingOccurrences(of: "\n", with: "\n|   "))" }.joined(separator: "\n"))
            └── \(last.printTree().replacingOccurrences(of: "\n", with: "\n    "))
            """
        } else {
            return "[]"
        }
    }
}

protocol Definition: Expression {
    var name: String { get }
    var body: any Expression { get }
    func renderLatexDefinition() -> String
}

extension Definition {
    func renderLatexBody() -> String {
        body.renderLatex()
    }
    
    func renderLatex() -> String {
        "\(renderLatexDefinition()) = \(renderLatexBody())"
    }
}

struct Literal: Expression {
    let val: BigDecimal
    
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        return self
    }
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        return val
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return .success([Float(val)])
    }
    
    func getVariables() -> [String] {
        return []
    }
    
    func getFunctions() -> [String] {
        return []
    }
    
    func renderLatex() -> String {
        if val.isInfinite {
            return "\\infty"
        }
        
        return val.asString()
    }
    
    func printTree() -> String {
        return val.asString()
    }
}

struct Variable: Expression {
    let name: String
    
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        return variables[name] ?? self
    }
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        return variables[name]?.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return variables[name]?.batch_eval(variables, functions) ?? .failure(.missingSymbol(type: "variable", name: name))
    }
    
    func getVariables() -> [String] {
        return [name]
    }
    
    func getFunctions() -> [String] {
        return []
    }
    
    func renderLatex() -> String {
        return renderSymbolLatex(name)
    }
    
    func printTree() -> String {
        return name
    }
}

struct Function: Expression {
    let name: String
    let args: [any Expression]
    
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        functions[name]?(args)?.apply(variables, functions) ?? self
    }
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        functions[name]?(args)?.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        if let f = functions[name] {
            if let expr = f(args) {
                return expr.batch_eval(variables, functions)
            } else {
                return .failure(.genericError(msg: "Failed to apply function: \(name)"))
            }
        } else {
            return .failure(.missingSymbol(type: "function", name: name))
        }
    }
    
    func getVariables() -> [String] {
        args.flatMap { expr in
            expr.getVariables()
        }
    }
    
    func getFunctions() -> [String] {
        args.flatMap { expr in
            expr.getFunctions()
        } + [name]
    }
    
    func renderLatex() -> String {
        "\(renderSymbolLatex(name, isFunc: true)){(\(args.map({$0.renderLatex()}).joined(separator: ", ")))}"
    }
    
    func printTree() -> String {
        if let last = args.last {
            return """
            \(name)(...)
            \(args.dropLast().map{ "├── \($0.printTree().replacingOccurrences(of: "\n", with: "\n|   "))" }.joined(separator: "\n"))
            └── \(last.printTree().replacingOccurrences(of: "\n", with: "\n    "))
            """
        } else {
            return "\(name)()"
        }
    }
}

struct Vector: Expression {
    var data: [any Expression]
    
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        let newData = data.compactMap { expr in
            expr.apply(variables, functions)
        }
        
        if newData.count == data.count {
            return Vector(data: newData)
        } else {
            return nil
        }
    }

    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        nil // figure out whether this should be implemented
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        data.map { expr in
            expr.batch_eval(variables, functions)
        }.flattenResults()
    }
    
    func getVariables() -> [String] {
        data.flatMap { expr in
            expr.getVariables()
        }
    }
    
    func getFunctions() -> [String] {
        data.flatMap { expr in
            expr.getFunctions()
        }
    }
    
    func renderLatex() -> String {
        "[\(data.map({$0.renderLatex()}).joined(separator: ", "))]"
    }
    
    func printTree() -> String {
        if let last = data.last {
            return """
            []
            \(data.dropLast().map{ "├── \($0.printTree().replacingOccurrences(of: "\n", with: "\n|   "))" }.joined(separator: "\n"))
            └── \(last.printTree().replacingOccurrences(of: "\n", with: "\n    "))
            """
        } else {
            return "[]"
        }
    }
}

struct FunctionDefinition: Definition {
    let name: String
    var args: [String]
    var body: any Expression
    
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        var copy = self
        if let body2 = copy.body.apply(variables, functions) {
            copy.body = body2
            copy.args = args.filter( {!variables.keys.contains($0)} )
        }
        
        return copy
    }

    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        if args.allSatisfy( {variables.keys.contains($0)} ) {
            return body.eval(variables, functions)
        } else {
            return nil
        }
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        let missingArgs = args.filter( {!variables.keys.contains($0)} )
        
        if missingArgs.isEmpty {
            return body.batch_eval(variables, functions)
        } else {
            return .failure(.errorList(errors: missingArgs.map( {.missingSymbol(type: "argument", name: $0)} )))
        }
    }
    
    func getVariables() -> [String] {
        body.getVariables()
    }
    
    func getFunctions() -> [String] {
        body.getFunctions()
    }
    
    func renderLatexDefinition() -> String {
        "\(renderSymbolLatex(name, isFunc: true)){(\(args.map({renderSymbolLatex($0)}).joined(separator: ", ")))}"
    }
    
    func printTree() -> String {
        return """
        \(name)(\(args.joined(separator: ", ")))=
        └── \(body.printTree().replacingOccurrences(of: "\n", with: "\n    "))
        """
    }
}

struct VariableDefinition: Definition {
    let name: String
    var body: any Expression
    
    func apply(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> (any Expression)? {
        var copy = self
        if let body2 = copy.body.apply(variables, functions) {
            copy.body = body2
        }
        
        return copy
    }

    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        return body.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return body.batch_eval(variables, functions)
    }
    
    func getVariables() -> [String] {
        body.getVariables()
    }
    
    func getFunctions() -> [String] {
        body.getFunctions()
    }
    
    func renderLatexDefinition() -> String {
        renderSymbolLatex(name)
    }
    
    func printTree() -> String {
        return """
        \(name)=
        └── \(body.printTree().replacingOccurrences(of: "\n", with: "\n    "))
        """
    }
}

struct Add: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "+"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 + v2
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vDSP.add(v1, v2)
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) + \(y.renderLatex())"
    }
}

struct Subtract: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "-"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 - v2
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vDSP.subtract(v1, v2)
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) - \(y.renderLatex())"
    }
}

struct Multiply: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "*"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 * v2
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vDSP.multiply(v1, v2)
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\cdot \(y.renderLatex())"
    }
}

struct Divide: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "/"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1.divide(v2, .decimal32)
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vDSP.divide(v1, v2)
    }
    
    func renderLatex() -> String {
        return "\\frac{\(x.renderLatex())}{\(y.renderLatex())}"
    }
}

struct FloorDivide: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "//"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 / v2
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vDSP.trunc(vDSP.divide(v1, v2))
    }
    
    func renderLatex() -> String {
        return "\\left\\lfloor\\frac{\(x.renderLatex())}{\(y.renderLatex())}\\right\\rfloor"
    }
}

struct Modulus: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "%"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 % v2
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vForce.remainder(dividends: v1, divisors: v2)
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\bmod \(y.renderLatex())"
    }
}

struct Exponent: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "^"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return .pow(v1, v2)
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vForce.pow(bases: v1, exponents: v2)
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex())^{\(y.renderLatex())}"
    }
}

struct SquareRoot: UnaryExpression {
    var x: any Expression
    
    static let symbol = "sqrt"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .sqrt(v, .decimal32)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.sqrt)
    }
    
    func renderLatex() -> String {
        return "\\sqrt{\(x.renderLatex())}"
    }
}

struct CubeRoot: UnaryExpression {
    var x: any Expression
    
    static let symbol = "cbrt"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return BigDecimal.root(v, 3)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map({vForce.pow(bases: $0, exponents: [Float(1/3)])})
    }
    
    func renderLatex() -> String {
        return "\\sqrt[3]{\(x.renderLatex())}"
    }
}

struct Factorial: UnaryExpression {
    var x: any Expression
    
    static let symbol = "!"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions)?.round(.decimal128) else { return nil }
        
        if (v <= 0 && BigDecimal.isIntValue(v)) {
            return nil
        }
        
        return .full_factorial(v, .decimal128)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.factorial)
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex())!"
    }
}

struct UnaryPlus: UnaryExpression {
    var x: any Expression
    
    static let symbol = "+"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        return x.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions)
    }
    
    func renderLatex() -> String {
        return "+\(x.renderLatex())"
    }
}

struct UnaryMinus: UnaryExpression {
    var x: any Expression
    
    static let symbol = "-"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return -v
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map({vDSP.multiply(-1, $0)})
    }
    
    func renderLatex() -> String {
        return "-\(x.renderLatex())"
    }
}

struct Grouping: UnaryExpression {
    var x: any Expression
    
    static let symbol = "()"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        return x.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions)
    }
    
    func renderLatex() -> String {
        return "\\left( \(x.renderLatex()) \\right)"
    }
}

struct Sine: UnaryExpression {
    var x: any Expression
    
    static let symbol = "sin"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .sin(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.sin)
    }
    
    func renderLatex() -> String {
        return "\\sin{\(x.renderLatex())}"
    }
}

struct Cosine: UnaryExpression {
    var x: any Expression
    
    static let symbol = "cos"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .cos(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.cos)
    }
    
    func renderLatex() -> String {
        return "\\cos{\(x.renderLatex())}"
    }
}

struct Tangent: UnaryExpression {
    var x: any Expression
    
    static let symbol = "tan"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .tan(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.tan)
    }
    
    func renderLatex() -> String {
        return "\\tan{\(x.renderLatex())}"
    }
}

struct ArcSine: UnaryExpression {
    var x: any Expression
    
    static let symbol = "arcsin"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .asin(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.asin)
    }
    
    func renderLatex() -> String {
        return "\\arcsin{\(x.renderLatex())}"
    }
}

struct ArcCosine: UnaryExpression {
    var x: any Expression
    
    static let symbol = "arccos"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .acos(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.acos)
    }
    
    func renderLatex() -> String {
        return "\\arccos{\(x.renderLatex())}"
    }
}

struct ArcTangent: UnaryExpression {
    var x: any Expression
    
    static let symbol = "arctan"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .atan(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.atan)
    }
    
    func renderLatex() -> String {
        return "\\arctan{\(x.renderLatex())}"
    }
}

struct Sinh: UnaryExpression {
    var x: any Expression
    
    static let symbol = "sinh"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .sinh(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.sinh)
    }
    
    func renderLatex() -> String {
        return "\\sinh{\(x.renderLatex())}"
    }
}

struct Cosh: UnaryExpression {
    var x: any Expression
    
    static let symbol = "cosh"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .cosh(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.cosh)
    }
    
    func renderLatex() -> String {
        return "\\cosh{\(x.renderLatex())}"
    }
}

struct Tanh: UnaryExpression {
    var x: any Expression
    
    static let symbol = "tanh"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .tanh(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.tanh)
    }
    
    func renderLatex() -> String {
        return "\\tanh{\(x.renderLatex())}"
    }
}

struct ArcSinh: UnaryExpression {
    var x: any Expression
    
    static let symbol = "arcsinh"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .asinh(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.asinh)
    }
    
    func renderLatex() -> String {
        return "\\sinh^{-1}{\(x.renderLatex())}"
    }
}

struct ArcCosh: UnaryExpression {
    var x: any Expression
    
    static let symbol = "arccosh"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .acosh(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.acosh)
    }
    
    func renderLatex() -> String {
        return "\\cosh^{-1}{\(x.renderLatex())}"
    }
}

struct ArcTanh: UnaryExpression {
    var x: any Expression
    
    static let symbol = "arctanh"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .atanh(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.atanh)
    }
    
    func renderLatex() -> String {
        return "\\tanh^{-1}{\(x.renderLatex())}"
    }
}

struct Ceiling: UnaryExpression {
    var x: any Expression
    
    static let symbol = "ceil"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return ceil(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.ceil)
    }
    
    func renderLatex() -> String {
        return "\\lceil{\(x.renderLatex())}\\rceil"
    }
}

struct Floor: UnaryExpression {
    var x: any Expression
    
    static let symbol = "floor"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return floor(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.floor)
    }
    
    func renderLatex() -> String {
        return "\\lfloor{\(x.renderLatex())}\\rfloor"
    }
}

struct Round: UnaryExpression {
    var x: any Expression
    
    static let symbol = "round"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return round(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.nearestInteger)
    }
    
    func renderLatex() -> String {
        return "\\operatorname{round}{(\(x.renderLatex()))}"
    }
}

struct BitwiseAnd: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "&"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        
        if (BigDecimal.isIntValue(v1) && BigDecimal.isIntValue(v2)) {
            return BigDecimal(integerLiteral: Int(v1) & Int(v2))
        } else {
            return nil
        }
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return []
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\& \(y.renderLatex())"
    }
}

struct BitwiseOr: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "|"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        
        if (BigDecimal.isIntValue(v1) && BigDecimal.isIntValue(v2)) {
            return BigDecimal(integerLiteral: Int(v1) | Int(v2))
        } else {
            return nil
        }
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return []
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\| \(y.renderLatex())"
    }
}

struct BitwiseXor: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "⊕"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        
        if (BigDecimal.isIntValue(v1) && BigDecimal.isIntValue(v2)) {
            return BigDecimal(integerLiteral: Int(v1) ^ Int(v2))
        } else {
            return nil
        }
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return []
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\oplus \(y.renderLatex())"
    }
}

struct LogarithmBase10: UnaryExpression {
    var x: any Expression
    
    static let symbol = "log10"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .log10(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.log10)
    }
    
    func renderLatex() -> String {
        return "\\log_{10}{(\(x.renderLatex()))}"
    }
}

struct NaturalLogarithm: UnaryExpression {
    var x: any Expression
    
    static let symbol = "ln"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .log(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.log)
    }
    
    func renderLatex() -> String {
        return "\\ln{(\(x.renderLatex()))}"
    }
}

struct Exponential: UnaryExpression {
    var x: any Expression
    
    static let symbol = "exp"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .exp(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.exp)
    }
    
    func renderLatex() -> String {
        return "e^{\(x.renderLatex())}"
    }
}

struct AbsoluteValue: UnaryExpression {
    var x: any Expression
    
    static let symbol = "abs"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return abs(v)
    }
    
    func batch_eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vDSP.absolute)
    }
    
    func renderLatex() -> String {
        return "\\left| \(x.renderLatex()) \\right|"
    }
}

struct Min: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "min"
    
    func eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        
        return BigDecimal.minimum(v1, v2)
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vDSP.minimum(v1, v2)
    }
    
    func renderLatex() -> String {
        "\\operatorname{min}{(\(x.renderLatex()), \(y.renderLatex()))}"
    }
}

struct Max: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "max"
    
    func eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        
        return BigDecimal.maximum(v1, v2)
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vDSP.maximum(v1, v2)
    }
    
    func renderLatex() -> String {
        "\\operatorname{max}{(\(x.renderLatex()), \(y.renderLatex()))}"
    }
}

struct Summation: NAryExpression {
    var args: [any Expression]
    
    init(from: any Expression, to: any Expression, value: any Expression) {
        self.args = [from, to, value]
    }
    
    static let n: Int = 3
    static let symbol = "sum"
    
    var from: any Expression {
        self.args[0]
    }
    
    var to: any Expression {
        self.args[1]
    }
    
    var value: any Expression {
        self.args[2]
    }
    
    func eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        var varName = "i"
        if let fromDef = from as? any Definition {
            if fromDef is FunctionDefinition {
                return nil
            }
            
            varName = fromDef.name
        }
        
        guard let fromVal = from.eval(variables, functions)?.rounded() else { return nil }
        guard let toVal = to.eval(variables, functions)?.rounded() else { return nil }
        
        var acc = BigDecimal.zero
        var i = fromVal
        while i <= toVal {
            var vars = variables
            vars[varName] = Literal(val: i)
            if let v = value.eval(vars, functions) {
                acc += v
            }
            
            i += 1
        }
        
        return acc
    }
    
    func batch_eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return .failure(.genericError(msg: "unimplemented"))
    }
    
    func getVariables() -> [String] {
        let vars = args.flatMap { expr in
            expr.getVariables()
        }
        
        return vars.filter({$0 != "i"})
    }
    
    func renderLatex() -> String {
        let fromStr = from is any Definition ? from.renderLatex() : "i=" + from.renderLatex()
        
        return "\\sum_{\(fromStr)}^{\(to.renderLatex())}{\(value.renderLatex())}"
    }
}

struct Product: NAryExpression {
    var args: [any Expression]
    
    init(from: any Expression, to: any Expression, value: any Expression) {
        self.args = [from, to, value]
    }
    
    static let n: Int = 3
    static let symbol = "prod"
    
    var from: any Expression {
        self.args[0]
    }
    
    var to: any Expression {
        self.args[1]
    }
    
    var value: any Expression {
        self.args[2]
    }
    
    func eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        var varName = "i"
        if let fromDef = from as? any Definition {
            if fromDef is FunctionDefinition {
                return nil
            }
            
            varName = fromDef.name
        }
        
        guard let fromVal = from.eval(variables, functions)?.rounded() else { return nil }
        guard let toVal = to.eval(variables, functions)?.rounded() else { return nil }
        
        var acc = BigDecimal.one
        var i = fromVal
        while i <= toVal {
            var vars = variables
            vars[varName] = Literal(val: i)
            if let v = value.eval(vars, functions) {
                acc *= v
            }
            
            i += 1
        }
        
        return acc
    }
    
    func batch_eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
        return .failure(.genericError(msg: "unimplemented"))
    }
    
    func getVariables() -> [String] {
        let vars = args.flatMap { expr in
            expr.getVariables()
        }
        
        return vars.filter({$0 != "i"})
    }
    
    func renderLatex() -> String {
        let fromStr = from is any Definition ? from.renderLatex() : "i=" + from.renderLatex()
        
        return "\\prod_{\(fromStr)}^{\(to.renderLatex())}{\(value.renderLatex())}"
    }
}

//struct Integration: NAryExpression {
//    var args: [Expression]
//    
//    init(from: any Expression, to: any Expression, value: any Expression) {
//        self.args = [from, to, value]
//    }
//    
//    static let n: Int = 3
//    static let symbol = "int"
//    
//    var from: any Expression {
//        self.args[0]
//    }
//    
//    var to: any Expression {
//        self.args[1]
//    }
//    
//    var value: any Expression {
//        self.args[2]
//    }
//    
//    func eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
//        var varName = "i"
//        if let fromDef = from as? Definition {
//            if fromDef is FunctionDefinition {
//                return nil
//            }
//            
//            varName = fromDef.name
//        }
//        
//        guard let fromVal = from.eval(variables, functions)?.rounded() else { return nil }
//        guard let toVal = to.eval(variables, functions)?.rounded() else { return nil }
//        
//        var acc = BigDecimal.zero
//        var i = fromVal
//        while i <= toVal {
//            var vars = variables
//            vars[varName] = Literal(val: i)
//            if let v = value.eval(vars, functions) {
//                acc += v
//            }
//            
//            i += 1
//        }
//        
//        return acc
//    }
//    
//    func batch_eval(_ variables: [String : any Expression], _ functions: [String : ([any Expression]) -> (any Expression)?]) -> Result<[Float], ExpressionError> {
//        return .failure(.genericError(msg: "unimplemented"))
//    }
//    
//    func renderLatex() -> String {
//        let fromStr = from is Definition ? from.renderLatex() : "i=" + from.renderLatex()
//        
//        return "\\int_{\(fromStr)}^{\(to.renderLatex())}{\(value.renderLatex())}"
//    }
//}

struct Coefficient: BinaryExpression {
    var x: any Expression
    var y: any Expression
    
    static let symbol = "Ax"
    
    func eval(_ variables: [String: any Expression], _ functions: [String: ([any Expression]) -> (any Expression)?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 * v2
    }
    
    static func _batch_eval(v1: [Float], v2: [Float]) -> [Float] {
        return vDSP.multiply(v1, v2)
    }
    
    func renderLatex() -> String {
        return x.renderLatex() + y.renderLatex()
    }
}

struct ExpressionTypes {
    static let allExpressions2: [any Expression.Type] = [
        Literal.self,
        Variable.self,
        Function.self,
        Vector.self,
        FunctionDefinition.self,
        VariableDefinition.self,
        Add.self,
        Subtract.self,
        Multiply.self,
        Divide.self,
        FloorDivide.self,
        Modulus.self,
        Exponent.self,
        SquareRoot.self,
        CubeRoot.self,
        Factorial.self,
        UnaryPlus.self,
        UnaryMinus.self,
        Grouping.self,
        Sine.self,
        Cosine.self,
        Tangent.self,
        ArcSine.self,
        ArcCosine.self,
        ArcTangent.self,
        Sinh.self,
        Cosh.self,
        Tanh.self,
        ArcSinh.self,
        ArcCosh.self,
        ArcTanh.self,
        Ceiling.self,
        Floor.self,
        Round.self,
        BitwiseAnd.self,
        BitwiseOr.self,
        BitwiseXor.self,
        LogarithmBase10.self,
        NaturalLogarithm.self,
        Exponential.self,
        AbsoluteValue.self,
        Min.self,
        Max.self,
        Summation.self,
        Product.self,
        Coefficient.self
    ]
    
    static let namedFunctions: [any Expression.Type] = [
        SquareRoot.self,
        CubeRoot.self,
        Sine.self,
        Cosine.self,
        Tangent.self,
        ArcSine.self,
        ArcCosine.self,
        ArcTangent.self,
        Sinh.self,
        Cosh.self,
        Tanh.self,
        ArcSinh.self,
        ArcCosh.self,
        ArcTanh.self,
        Ceiling.self,
        Floor.self,
        Round.self,
        LogarithmBase10.self,
        NaturalLogarithm.self,
        Exponential.self,
        AbsoluteValue.self,
        Min.self,
        Max.self,
        Summation.self,
        Product.self
    ]
    
    static let namedFunctionArgs = Dictionary(
        namedFunctions.compactMap { expr in
            if let expr = expr as? any UnaryExpression.Type {
                return (expr.symbol, 1)
            } else if let expr = expr as? any BinaryExpression.Type {
                return (expr.symbol, 2)
            } else if let expr = expr as? any NAryExpression.Type {
                return (expr.symbol, expr.n)
            } else {
                return nil
            }
        }, 
        uniquingKeysWith: { x, y in x }
    )
}

extension Array {
    func flattenResults<T>() -> Result<[T], ExpressionError> where Element == Result<[T], ExpressionError> {
        var flattenedArray: [T] = []
        var errorList: [ExpressionError] = []
        
        for result in self {
            switch result {
            case .success(let array):
                flattenedArray.append(contentsOf: array)
            case .failure(let error):
                errorList.append(error)
            }
        }
        
        if errorList.isEmpty {
            return .success(flattenedArray)
        } else {
            return .failure(.errorList(errors: errorList))
        }
    }
    
    func repeatTo(_ x: Int) throws -> Array {
        if x % self.count != 0 {
            throw ExpressionError.genericError(msg: "Improper vector repeatTo attempt: \(self.count) -> \(x)")
        }
        let repeats = x / self.count
        
        return [[Element]].init(repeating: self, count: repeats).flatMap({$0})
    }
}

extension Result {
    func optionalError() -> Failure? {
        if case .failure(let err) = self {
            err
        } else {
            nil
        }
    }
}

extension BigDecimal {
    static func full_gamma(_ x: BigDecimal, _ mc: Rounding) -> BigDecimal {
        if x < 0 {
            return BigDecimal.pi / (BigDecimal.gamma(1-x, mc)*BigDecimal.sin(BigDecimal.pi * x))
        } else {
            return BigDecimal.gamma(x, mc)
        }
    }
    
    static func full_factorial(_ x: BigDecimal, _ mc: Rounding) -> BigDecimal {
        return full_gamma(x+1, mc)
    }
}


extension vForce {
    static let lanczos_g: Float = 5
    static let lanczos_n = 7
    static let lanczos_p: [Float] = [
        1.0000000001900148240,
        76.180091729471463483,
        -86.505320329416767652,
        24.014098240830910490,
        -1.2317395724501553875,
        0.0012086509738661785061,
        -5.3952393849531283785e-6
    ]
    
    static let sqrt2pi: Float = sqrtf(.pi*2)

    static func lanczos_a<U>(_ vector: U) -> [Float] where U : AccelerateBuffer, U.Element == Float {
        var acc = [Float](repeating: lanczos_p[0], count: vector.count)
        
        for i in 1..<self.lanczos_n {
            vDSP.add(vDSP.divide(lanczos_p[i], vDSP.add(Float(i), vector)), acc, result: &acc)
        }
        
        return acc
    }
    
    static func lanczos_gamma<U, V>(_ vector: U, result: inout V) where U : AccelerateBuffer, V : AccelerateMutableBuffer, U.Element == Float, V.Element == Float {
        vDSP.clear(&result)
        vDSP.add(self.sqrt2pi, result, result: &result)
        vDSP.multiply(result, vForce.pow(bases: vDSP.add(lanczos_g - 0.5, vector), exponents: vDSP.add(-0.5, vector)), result: &result)
        vDSP.multiply(result, vForce.exp(vDSP.negative(vDSP.add(lanczos_g - 0.5, vector))), result: &result)
        vDSP.multiply(result, lanczos_a(vDSP.add(-1, vector)), result: &result)
    }
    
    static func gamma<U>(_ vector: U) -> [Float] where U : AccelerateBuffer, U.Element == Float {
        let dirMask = vForce.copysign(magnitudes: [Float](repeating: 1.0, count: vector.count), signs: vDSP.add(-0.5, vector)) // -1 if <0.5, else +1
        let bitMask = vDSP.absolute(vDSP.divide(vDSP.add(-1, dirMask), 2)) // 1 if <0.5, else 0
        
        var buf: [Float] = vector as! [Float]
        vDSP.multiply(dirMask, buf, result: &buf) // -z
        vDSP.add(bitMask, buf, result: &buf) // 1-z
        vForce.lanczos_gamma(buf, result: &buf) // g(1-z)
        
        var sinPiMask = vDSP.multiply(.pi, vector) // pi*z
        vForce.sin(sinPiMask, result: &sinPiMask) // sin(pi*z)
        vForce.pow(bases: sinPiMask, exponents: bitMask, result: &sinPiMask) // sin(pi*z) or 1
        
        vDSP.multiply(sinPiMask, buf, result: &buf) // g(1-z)*sin(pi*z)
        vForce.pow(bases: buf, exponents: dirMask, result: &buf) // 1/(g(1-z)*sin(pi*z))
        vDSP.multiply(vForce.pow(bases: [Float](repeating: .pi, count: vector.count), exponents: bitMask), buf, result: &buf) // pi/(g(1-z)*sin(pi*z))
        
        return buf
    }
    
    static func factorial<U>(_ vector: U) -> [Float] where U : AccelerateBuffer, U.Element == Float {
        return vForce.gamma(vDSP.add(1, vector))
    }
}

func renderSymbolLatex(_ name: String, isFunc: Bool = false) -> String {
    let format = isFunc ? "operatorname" : "mathit"
    
    if (try? /[a-zA-Z](_{\d+})?/.wholeMatch(in: name)) != nil {
        return "\(name)"
    } else {
        return "\\\(format){\(name)}"
    }
}

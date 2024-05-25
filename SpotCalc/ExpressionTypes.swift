//
//  ExpressionTypes.swift
//  SpotCalc
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
    func apply(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Expression?
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal?
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError>
    func getVariables() -> [String]
    func getFunctions() -> [String]
    func renderLatex() -> String
    func printTree() -> String
}

extension Expression {
    func makeFunction(_ globalVariables: [String: Expression]) -> ([String], ([Expression]) -> Expression?) {
        let inputNames: [String] = self.getVariables().filter { v in
            !globalVariables.contains(where: {$0.key == v})
        }
        
        let function: ([Expression]) -> Expression? = { (inputExpressions: [Expression]) -> Expression? in
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
    var x: Expression { get set }
    var symbol: String { get }
}

extension UnaryExpression {
    func apply(_ variables: [String : Expression], _ functions: [String : ([Expression]) -> Expression?]) -> Expression? {
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
        \(symbol)
        └── \(x.printTree().replacingOccurrences(of: "\n", with: "\n    "))
        """
    }
}

protocol BinaryExpression: Expression {
    var x: Expression { get set }
    var y: Expression { get set }
    var symbol: String { get }
}

extension BinaryExpression {
    func apply(_ variables: [String : Expression], _ functions: [String : ([Expression]) -> Expression?]) -> Expression? {
        var copy = self
        if let x2 = copy.x.apply(variables, functions), let y2 = copy.y.apply(variables, functions) {
            copy.x = x2
            copy.y = y2
        }
        
        return copy
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
        \(symbol)
        ├── \(x.printTree().replacingOccurrences(of: "\n", with: "\n|   "))
        └── \(y.printTree().replacingOccurrences(of: "\n", with: "\n    "))
        """
    }
}

struct Literal: Expression {
    let val: BigDecimal
    
    func apply(_ variables: [String : Expression], _ functions: [String : ([Expression]) -> Expression?]) -> Expression? {
        return self
    }
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        return val
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return .success([Float(val)])
    }
    
    func getVariables() -> [String] {
        return []
    }
    
    func getFunctions() -> [String] {
        return []
    }
    
    func renderLatex() -> String {
        return val.asString()
    }
    
    func printTree() -> String {
        return val.asString()
    }
}

struct Variable: Expression {
    let name: String
    
    func apply(_ variables: [String : Expression], _ functions: [String : ([Expression]) -> Expression?]) -> Expression? {
        return variables[name]
    }
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        return variables[name]?.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return variables[name]?.batch_eval(variables, functions) ?? .failure(.missingSymbol(type: "variable", name: name))
    }
    
    func getVariables() -> [String] {
        return [name]
    }
    
    func getFunctions() -> [String] {
        return []
    }
    
    func renderLatex() -> String {
        return name
    }
    
    func printTree() -> String {
        return name
    }
}

struct Function: Expression {
    let name: String
    let args: [Expression]
    
    func apply(_ variables: [String : Expression], _ functions: [String : ([Expression]) -> Expression?]) -> Expression? {
        functions[name]?(args)
    }
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        functions[name]?(args)?.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
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
        []
    }
    
    func getFunctions() -> [String] {
        [name]
    }
    
    func renderLatex() -> String {
        "\\operatorname{\(name)}{(\(args.map({$0.renderLatex()}).joined(separator: ", ")))}"
    }
    
    func printTree() -> String {
        "\(name)(...)"
    }
}

struct List: Expression {
    var data: [Expression]
    
    func apply(_ variables: [String : any Expression], _ functions: [String : ([Expression]) -> Expression?]) -> Expression? {
        let newData = data.compactMap { expr in
            expr.apply(variables, functions)
        }
        
        if newData.count == data.count {
            return List(data: newData)
        } else {
            return nil
        }
    }

    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        nil // figure out whether this should be implemented
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
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
        "[]"
    }
}

struct Add: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "+"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 + v2
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let prod = v1.count * v2.count
                        
            do {
                let v1 = try v1.repeatTo(prod)
                let v2 = try v2.repeatTo(prod)

                return .success(vDSP.add(v1, v2))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) + \(y.renderLatex())"
    }
}

struct Subtract: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "-"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 - v2
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let prod = v1.count * v2.count
                        
            do {
                let v1 = try v1.repeatTo(prod)
                let v2 = try v2.repeatTo(prod)
                
                return .success(vDSP.subtract(v1, v2))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) - \(y.renderLatex())"
    }
}

struct Multiply: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "*"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 * v2
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let prod = v1.count * v2.count
                        
            do {
                let v1 = try v1.repeatTo(prod)
                let v2 = try v2.repeatTo(prod)
                
                return .success(vDSP.multiply(v1, v2))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\cdot \(y.renderLatex())"
    }
}

struct Divide: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "/"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1.divide(v2, .decimal32)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let prod = v1.count * v2.count
                        
            do {
                let v1 = try v1.repeatTo(prod)
                let v2 = try v2.repeatTo(prod)
                
                return .success(vDSP.divide(v1, v2))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func renderLatex() -> String {
        return "\\frac{\(x.renderLatex())}{\(y.renderLatex())}"
    }
}

struct FloorDivide: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "//"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 / v2
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let prod = v1.count * v2.count
                        
            do {
                let v1 = try v1.repeatTo(prod)
                let v2 = try v2.repeatTo(prod)
                
                return .success(vDSP.trunc(vDSP.divide(v1, v2)))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func renderLatex() -> String {
        return "\\left\\lfloor\\frac{\(x.renderLatex())}{\(y.renderLatex())}\\right\\rfloor"
    }
}

struct Modulus: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "%"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 % v2
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let prod = v1.count * v2.count
            
            do {
                let v1 = try v1.repeatTo(prod)
                let v2 = try v2.repeatTo(prod)
                
                return .success(vForce.remainder(dividends: v1, divisors: v2))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\bmod \(y.renderLatex())"
    }
}

struct Exponent: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "^"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return .pow(v1, v2)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let prod = v1.count * v2.count
            
            do {
                let v1 = try v1.repeatTo(prod)
                let v2 = try v2.repeatTo(prod)
                
                return .success(vForce.pow(bases: v1, exponents: v2))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex())^{\(y.renderLatex())}"
    }
}

struct SquareRoot: UnaryExpression {
    var x: Expression
    
    let symbol = "sqrt"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .sqrt(v, .decimal32)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.sqrt)
    }
    
    func renderLatex() -> String {
        return "\\sqrt{\(x.renderLatex())}"
    }
}

struct CubeRoot: UnaryExpression {
    var x: Expression
    
    let symbol = "cbrt"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return BigDecimal.root(v, 3)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map({vForce.pow(bases: $0, exponents: [Float(1/3)])})
    }
    
    func renderLatex() -> String {
        return "\\sqrt[3]{\(x.renderLatex())}"
    }
}

struct Factorial: UnaryExpression {
    var x: Expression
    
    let symbol = "!"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions)?.round(.decimal128) else { return nil }
        
        if (v <= 0 && BigDecimal.isIntValue(v)) {
            return nil
        }
        
        return .full_factorial(v, .decimal128)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.factorial)
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex())!"
    }
}

struct UnaryPlus: UnaryExpression {
    var x: Expression
    
    let symbol = "+"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        return x.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions)
    }
    
    func renderLatex() -> String {
        return "+\(x.renderLatex())"
    }
}

struct UnaryMinus: UnaryExpression {
    var x: Expression
    
    let symbol = "-"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return -v
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map({vDSP.multiply(-1, $0)})
    }
    
    func renderLatex() -> String {
        return "-\(x.renderLatex())"
    }
}

struct Grouping: UnaryExpression {
    var x: Expression
    
    let symbol = "()"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        return x.eval(variables, functions)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions)
    }
    
    func renderLatex() -> String {
        return "\\left( \(x.renderLatex()) \\right)"
    }
}

struct Sine: UnaryExpression {
    var x: Expression
    
    let symbol = "sin"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .sin(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.sin)
    }
    
    func renderLatex() -> String {
        return "\\sin{\(x.renderLatex())}"
    }
}

struct Cosine: UnaryExpression {
    var x: Expression
    
    let symbol = "cos"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .cos(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.cos)
    }
    
    func renderLatex() -> String {
        return "\\cos{\(x.renderLatex())}"
    }
}

struct Tangent: UnaryExpression {
    var x: Expression
    
    let symbol = "tan"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .tan(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.tan)
    }
    
    func renderLatex() -> String {
        return "\\tan{\(x.renderLatex())}"
    }
}

struct ArcSine: UnaryExpression {
    var x: Expression
    
    let symbol = "arcsin"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .asin(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.asin)
    }
    
    func renderLatex() -> String {
        return "\\arcsin{\(x.renderLatex())}"
    }
}

struct ArcCosine: UnaryExpression {
    var x: Expression
    
    let symbol = "arccos"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .acos(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.acos)
    }
    
    func renderLatex() -> String {
        return "\\arccos{\(x.renderLatex())}"
    }
}

struct ArcTangent: UnaryExpression {
    var x: Expression
    
    let symbol = "arctan"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .atan(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.atan)
    }
    
    func renderLatex() -> String {
        return "\\arctan{\(x.renderLatex())}"
    }
}

struct Sinh: UnaryExpression {
    var x: Expression
    
    let symbol = "sinh"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .sinh(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.sinh)
    }
    
    func renderLatex() -> String {
        return "\\sinh{\(x.renderLatex())}"
    }
}

struct Cosh: UnaryExpression {
    var x: Expression
    
    let symbol = "cosh"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .cosh(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.cosh)
    }
    
    func renderLatex() -> String {
        return "\\cosh{\(x.renderLatex())}"
    }
}

struct Tanh: UnaryExpression {
    var x: Expression
    
    let symbol = "tanh"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .tanh(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.tanh)
    }
    
    func renderLatex() -> String {
        return "\\tanh{\(x.renderLatex())}"
    }
}

struct ArcSinh: UnaryExpression {
    var x: Expression
    
    let symbol = "arcsinh"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .asinh(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.asinh)
    }
    
    func renderLatex() -> String {
        return "\\sinh^{-1}{\(x.renderLatex())}"
    }
}

struct ArcCosh: UnaryExpression {
    var x: Expression
    
    let symbol = "arccosh"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .acosh(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.acosh)
    }
    
    func renderLatex() -> String {
        return "\\cosh^{-1}{\(x.renderLatex())}"
    }
}

struct ArcTanh: UnaryExpression {
    var x: Expression
    
    let symbol = "arctanh"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .atanh(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.atanh)
    }
    
    func renderLatex() -> String {
        return "\\tanh^{-1}{\(x.renderLatex())}"
    }
}

struct Ceiling: UnaryExpression {
    var x: Expression
    
    let symbol = "ceil"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return ceil(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.ceil)
    }
    
    func renderLatex() -> String {
        return "\\lceil{\(x.renderLatex())}\\rceil"
    }
}

struct Floor: UnaryExpression {
    var x: Expression
    
    let symbol = "floor"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return floor(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.floor)
    }
    
    func renderLatex() -> String {
        return "\\lfloor{\(x.renderLatex())}\\rfloor"
    }
}

struct Round: UnaryExpression {
    var x: Expression
    
    let symbol = "round"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return round(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.nearestInteger)
    }
    
    func renderLatex() -> String {
        return "\\operatorname{round}{(\(x.renderLatex()))}"
    }
}

struct BitwiseAnd: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "&"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        
        if (BigDecimal.isIntValue(v1) && BigDecimal.isIntValue(v2)) {
            return BigDecimal(integerLiteral: Int(v1) & Int(v2))
        } else {
            return nil
        }
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return .failure(.genericError(msg: "Bitwise AND is an invalid operation for floats"))
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\& \(y.renderLatex())"
    }
}

struct BitwiseOr: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "|"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        
        if (BigDecimal.isIntValue(v1) && BigDecimal.isIntValue(v2)) {
            return BigDecimal(integerLiteral: Int(v1) | Int(v2))
        } else {
            return nil
        }
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return .failure(.genericError(msg: "Bitwise OR is an invalid operation for floats"))
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\| \(y.renderLatex())"
    }
}

struct BitwiseXor: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "⊕"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        
        if (BigDecimal.isIntValue(v1) && BigDecimal.isIntValue(v2)) {
            return BigDecimal(integerLiteral: Int(v1) ^ Int(v2))
        } else {
            return nil
        }
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return .failure(.genericError(msg: "Bitwise XOR is an invalid operation for floats"))
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\oplus \(y.renderLatex())"
    }
}

struct LogarithmBase10: UnaryExpression {
    var x: Expression
    
    let symbol = "log10"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .log10(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.log10)
    }
    
    func renderLatex() -> String {
        return "\\log_{10}{(\(x.renderLatex()))}"
    }
}

struct NaturalLogarithm: UnaryExpression {
    var x: Expression
    
    let symbol = "ln"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .log(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.log)
    }
    
    func renderLatex() -> String {
        return "\\ln{(\(x.renderLatex()))}"
    }
}

struct Exponential: UnaryExpression {
    var x: Expression
    
    let symbol = "exp"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return .exp(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vForce.exp)
    }
    
    func renderLatex() -> String {
        return "e^{\(x.renderLatex())}"
    }
}

struct AbsoluteValue: UnaryExpression {
    var x: Expression
    
    let symbol = "abs"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions) else { return nil }
        return abs(v)
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        return x.batch_eval(variables, functions).map(vDSP.absolute)
    }
    
    func renderLatex() -> String {
        return "\\left| \(x.renderLatex()) \\right|"
    }
}

struct Coefficient: BinaryExpression {
    var x: Expression
    var y: Expression
    
    let symbol = "Ax"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v1 = x.eval(variables, functions) else { return nil }
        guard let v2 = y.eval(variables, functions) else { return nil }
        return v1 * v2
    }
    
    func batch_eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Result<[Float], ExpressionError> {
        let v1 = x.batch_eval(variables, functions)
        let v2 = y.batch_eval(variables, functions)
        
        if let v1 = try? v1.get(), let v2 = try? v2.get() {
            let prod = v1.count * v2.count
                        
            do {
                let v1 = try v1.repeatTo(prod)
                let v2 = try v2.repeatTo(prod)

                return .success(vDSP.multiply(v1, v2))
            } catch let error as ExpressionError {
                return .failure(error)
            } catch {
                return .failure(.genericError(msg: error.localizedDescription))
            }
        } else {
            return [v1, v2].flattenResults()
        }
    }
    
    func renderLatex() -> String {
        return x.renderLatex() + y.renderLatex()
    }
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

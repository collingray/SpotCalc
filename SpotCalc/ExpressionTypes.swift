//
//  ExpressionTypes.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/18/24.
//

import Foundation
import BigDecimal

protocol Expression {
    func apply(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> Expression?
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal?
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
    
    func getVariables() -> [String] {
        return []
    }
    
    func getFunctions() -> [String] {
        return []
    }
    
    func renderLatex() -> String {
        return "\(val)"
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
        return functions[name]?(args)
    }
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        return functions[name]?(args)?.eval(variables, functions)
    }
    
    func getVariables() -> [String] {
        return []
    }
    
    func getFunctions() -> [String] {
        return [name]
    }
    
    func renderLatex() -> String {
        "\\operatorname{\(name)}{(\(args.map({$0.renderLatex()}).joined(separator: ", ")))}"
    }
    
    func printTree() -> String {
        return "\(name)(...)"
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
    
    func renderLatex() -> String {
        return "\\sqrt[3]{\(x.renderLatex())}"
    }
}

struct Factorial: UnaryExpression {
    var x: Expression
    
    let symbol = "!"
    
    func eval(_ variables: [String: Expression], _ functions: [String: ([Expression]) -> Expression?]) -> BigDecimal? {
        guard let v = x.eval(variables, functions)?.round(.decimal32) else { return nil }
        
        if (v <= 0 && BigDecimal.isIntValue(v)) || v <= -9 {
            return nil
        }
        
        return .factorial(v, .decimal32)
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
    
    func renderLatex() -> String {
        return "\\left| \(x.renderLatex()) \\right|"
    }
}

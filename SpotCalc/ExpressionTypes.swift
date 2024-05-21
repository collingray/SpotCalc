//
//  ExpressionTypes.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/18/24.
//

import Foundation

protocol Expression {
    func eval(_ variables: [String: Expression]) -> Float?
    func getVariables() -> Set<String>
    func renderLatex() -> String
}

protocol UnaryExpression: Expression {
    var x: Expression { get }
}

extension UnaryExpression {
    func getVariables() -> Set<String> {
        return x.getVariables()
    }
}

protocol BinaryExpression: Expression {
    var x: Expression { get }
    var y: Expression { get }
}

extension BinaryExpression {
    func getVariables() -> Set<String> {
        return x.getVariables().union(y.getVariables())
    }
}

struct Literal: Expression {
    let val: Float
    
    func eval(_ variables: [String: Expression]) -> Float? {
        return val
    }
    
    func getVariables() -> Set<String> {
        return Set()
    }
    
    func renderLatex() -> String {
        return "\(val)"
    }
}

struct Variable: Expression {
    let name: String
    
    func eval(_ variables: [String: Expression]) -> Float? {
        return variables[name]?.eval(variables)
    }
    
    func getVariables() -> Set<String> {
        return Set([name])
    }
    
    func renderLatex() -> String {
        return name
    }
}

struct Add: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return v1 + v2
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) + \(y.renderLatex())"
    }
}

struct Subtract: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return v1 - v2
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) - \(y.renderLatex())"
    }
}

struct Multiply: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return v1 * v2
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\cdot \(y.renderLatex())"
    }
}

struct Divide: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return v1 / v2
    }
    
    func renderLatex() -> String {
        return "\\frac{\(x.renderLatex())}{\(y.renderLatex())}"
    }
}

struct Modulus: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return Float(Int(v1) % Int(v2))
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\bmod \(y.renderLatex())"
    }
}

struct Exponent: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let b = x.eval(variables) else { return nil }
        guard let e = y.eval(variables) else { return nil }
        return pow(b, e)
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex())^{\(y.renderLatex())}"
    }
}

struct SquareRoot: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return sqrt(v)
    }
    
    func renderLatex() -> String {
        return "\\sqrt{\(x.renderLatex())}"
    }
}

struct CubeRoot: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return cbrt(v)
    }
    
    func renderLatex() -> String {
        return "\\sqrt[3]{\(x.renderLatex())}"
    }
}

struct Factorial: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return Float((1...Int(v)).reduce(1, *))
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex())!"
    }
}

struct UnaryPlus: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        return x.eval(variables)
    }
    
    func renderLatex() -> String {
        return "+\(x.renderLatex())"
    }
}

struct UnaryMinus: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return -v
    }
    
    func renderLatex() -> String {
        return "-\(x.renderLatex())"
    }
}

struct Grouping: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        return x.eval(variables)
    }
    
    func renderLatex() -> String {
        return "\\left( \(x.renderLatex()) \\right)"
    }
}

struct Sine: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return sin(v)
    }
    
    func renderLatex() -> String {
        return "\\sin{\(x.renderLatex())}"
    }
}

struct Cosine: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return cos(v)
    }
    
    func renderLatex() -> String {
        return "\\cos{\(x.renderLatex())}"
    }
}

struct Tangent: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return tan(v)
    }
    
    func renderLatex() -> String {
        return "\\tan{\(x.renderLatex())}"
    }
}

struct ArcSine: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return asin(v)
    }
    
    func renderLatex() -> String {
        return "\\arcsin{\(x.renderLatex())}"
    }
}

struct ArcCosine: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return acos(v)
    }
    
    func renderLatex() -> String {
        return "\\arccos{\(x.renderLatex())}"
    }
}

struct ArcTangent: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return atan(v)
    }
    
    func renderLatex() -> String {
        return "\\arctan{\(x.renderLatex())}"
    }
}

struct Sinh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return sinh(v)
    }
    
    func renderLatex() -> String {
        return "\\sinh{\(x.renderLatex())}"
    }
}

struct Cosh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return cosh(v)
    }
    
    func renderLatex() -> String {
        return "\\cosh{\(x.renderLatex())}"
    }
}

struct Tanh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return tanh(v)
    }
    
    func renderLatex() -> String {
        return "\\tanh{\(x.renderLatex())}"
    }
}

struct ArcSinh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return asinh(v)
    }
    
    func renderLatex() -> String {
        return "\\sinh^{-1}{\(x.renderLatex())}"
    }
}

struct ArcCosh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return acosh(v)
    }
    
    func renderLatex() -> String {
        return "\\cosh^{-1}{\(x.renderLatex())}"
    }
}

struct ArcTanh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return atanh(v)
    }
    
    func renderLatex() -> String {
        return "\\tanh^{-1}{\(x.renderLatex())}"
    }
}

struct Ceiling: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return ceil(v)
    }
    
    func renderLatex() -> String {
        return "\\lceil{\(x.renderLatex())}\\rceil"
    }
}

struct Floor: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return floor(v)
    }
    
    func renderLatex() -> String {
        return "\\lfloor{\(x.renderLatex())}\\rfloor"
    }
}

struct Round: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return round(v)
    }
    
    func renderLatex() -> String {
        return "\\operatorname{round}{(\(x.renderLatex()))}"
    }
}

struct BitwiseAnd: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return Float(Int(v1) & Int(v2))
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\& \(y.renderLatex())"
    }
}

struct BitwiseOr: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return Float(Int(v1) | Int(v2))
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\| \(y.renderLatex())"
    }
}

struct BitwiseXor: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return Float(Int(v1) ^ Int(v2))
    }
    
    func renderLatex() -> String {
        return "\(x.renderLatex()) \\oplus \(y.renderLatex())"
    }
}

struct LogarithmBase10: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return log10(v)
    }
    
    func renderLatex() -> String {
        return "\\log_{10}{(\(x.renderLatex()))}"
    }
}

struct NaturalLogarithm: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return log(v)
    }
    
    func renderLatex() -> String {
        return "\\ln{(\(x.renderLatex()))}"
    }
}

struct Exponential: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return exp(v)
    }
    
    func renderLatex() -> String {
        return "e^{\(x.renderLatex())}"
    }
}

struct AbsoluteValue: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return abs(v)
    }
    
    func renderLatex() -> String {
        return "\\left| \(x.renderLatex()) \\right|"
    }
}

struct Erf: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return erf(v)
    }
    
    func renderLatex() -> String {
        return "\\operatorname{erf}{(\(x.renderLatex()))}"
    }
}

struct Erfc: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return erfc(v)
    }
    
    func renderLatex() -> String {
        return "\\operatorname{erfc}{(\(x.renderLatex()))}"
    }
}

struct NamedFunction: UnaryExpression {
    let x: Expression
    let name: String
    
    func eval(_ variables: [String: Expression]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return v // todo
    }
    
    func renderLatex() -> String {
        "\\operatorname{\(name)}{(\(x.renderLatex()))}"
    }
}

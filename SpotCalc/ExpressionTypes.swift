//
//  ExpressionTypes.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/18/24.
//

import Foundation

protocol Expression {
    func eval(_ variables: [String: Float]) -> Float?
    func getVariables() -> Set<String>
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
        return x.getVariables()
    }
}

struct Literal: Expression {
    let val: Float
    
    func eval(_ variables: [String: Float]) -> Float? {
        return val
    }
    
    func getVariables() -> Set<String> {
        return Set()
    }
}

struct Variable: Expression {
    let name: String
    
    func eval(_ variables: [String: Float]) -> Float? {
        return variables[name]
    }
    
    func getVariables() -> Set<String> {
        return Set([name])
    }
}

struct Add: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return v1 + v2
    }
}

struct Subtract: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return v1 - v2
    }
}

struct Multiply: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return v1 * v2
    }
}

struct Divide: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return v1 / v2
    }
}

struct Modulus: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return Float(Int(v1) % Int(v2))
    }
}

protocol Exponent: BinaryExpression {
    var x: Expression { get }
    var y: Expression { get }
}

struct CaretExponent: Exponent {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let b = x.eval(variables) else { return nil }
        guard let e = y.eval(variables) else { return nil }
        return pow(b, e)
    }
}

struct StarStarExponent: Exponent {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let b = x.eval(variables) else { return nil }
        guard let e = y.eval(variables) else { return nil }
        return pow(b, e)
    }
}

struct SquareRoot: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return sqrt(v)
    }
}

struct CubeRoot: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return cbrt(v)
    }
}

struct Factorial: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return Float((1...Int(v)).reduce(1, *))
    }
}

struct UnaryPlus: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        return x.eval(variables)
    }
}

struct UnaryMinus: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        return x.eval(variables)
    }
}

struct Grouping: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        return x.eval(variables)
    }
}

struct Sine: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return sin(v)
    }
}

struct Cosine: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return cos(v)
    }
}

struct Tangent: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return tan(v)
    }
}

struct SineDegree: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return sin(v * .pi / 180)
    }
}

struct CosineDegree: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return cos(v * .pi / 180)
    }
}

struct TangentDegree: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return tan(v * .pi / 180)
    }
}

struct ArcSine: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return asin(v)
    }
}

struct ArcCosine: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return acos(v)
    }
}

struct ArcTangent: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return atan(v)
    }
}

struct ArcSineDegree: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return asin(v) * 180 / .pi
    }
}

struct ArcCosineDegree: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return acos(v) * 180 / .pi
    }
}

struct ArcTangentDegree: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return atan(v) * 180 / .pi
    }
}

struct Sinh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return sinh(v)
    }
}

struct Cosh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return cosh(v)
    }
}

struct Tanh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return tanh(v)
    }
}

struct ArcSinh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return asinh(v)
    }
}

struct ArcCosh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return acosh(v)
    }
}

struct ArcTanh: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return atanh(v)
    }
}

struct Ceiling: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return ceil(v)
    }
}

struct Floor: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return floor(v)
    }
}

struct Round: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return round(v)
    }
}

struct BitwiseAnd: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return Float(Int(v1) & Int(v2))
    }
}

struct BitwiseOr: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return Float(Int(v1) | Int(v2))
    }
}

struct BitwiseXor: BinaryExpression {
    let x: Expression
    let y: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v1 = x.eval(variables) else { return nil }
        guard let v2 = y.eval(variables) else { return nil }
        return Float(Int(v1) ^ Int(v2))
    }
}

struct LogarithmBase10: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return log10(v)
    }
}

struct NaturalLogarithm: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return log(v)
    }
}

struct Exponential: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return exp(v)
    }
}

struct AbsoluteValue: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return abs(v)
    }
}

struct Erf: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return erf(v)
    }
}

struct Erfc: UnaryExpression {
    let x: Expression
    
    func eval(_ variables: [String: Float]) -> Float? {
        guard let v = x.eval(variables) else { return nil }
        return erfc(v)
    }
}

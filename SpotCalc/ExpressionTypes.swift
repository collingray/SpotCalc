//
//  ExpressionTypes.swift
//  SpotCalc
//
//  Created by Collin Gray on 5/18/24.
//

import Foundation

//Basic: 1 + 1 = 2, 1 - 1 = 0, 2 * 3 = 6, 6 / 2 = 3
//Precendence: 2 + 3 * 5 = 17
//Parentheses: (1 + 1) / 2 = 2
//Multiplication (Implied): 2(8+1) = 18
//Absolute Value: abs(-1.1) = fabs(-1.1) = 1.1
//Percentage: 25% = 0.25, 60 * 25% = 15
//Include unit in formula: 5 miles * 4 = 20 miles
//Include a unit conversion in formula: 5 miles * 4 in km = 32.19 kilometers
//Use a rate with units in a formula: 20 mph * 5 hours = 100 miles
//Modulus (Remainder): 5 % 2 = 1
//Base 10 and Natural Logarithms: log(10) = 1, ln(e) = 1,
//Exponentiation: 2^3 = 2 ** 3 = 8
//Exponentiation (Natural Base): e^2 = e ** 2 = exp(2) = 7,3890560989
//Square and Cube Roots: sqrt(4) = 2, cbrt(27) = 3
//Factorial: 3! = 6
//Trigonometric (Radian): sin(pi/2) = 1, cos(pi) = -1, tan(pi/4) = 1
//Trigonometric (Degree): sind(90) = 1, cosd(180) = -1, tand(45) = 1
//Trigonometric (Degree): sin(90deg) = 1, cos(180deg) = -1, tan(45deg) = 1
//Inverse Trigonometric (Radian): arcsin(1) = 1,57 radians, arccos(-1) = 3,14 radians, arctan(1) = 0,79 radians
//Inverse Trigonometric (Degree): arcsind(1) = 90 degrees, arccosd(-1) = 180 degrees, tand(1) = 45 degrees
//Hyperbolic: sinh(1) = 1.1752011936, cosh(0) = 1, tanh(0) = 0
//Inverse Hyperpolic: arcsinh(1) = 0.881373587; arccosh(1) = 0, arctanh(0.5) = 0.5493061443
//Rounding: ceil(1.2) = 2, floor(1.2) = 1, round(1.6) = 2
//Bitwise Operators: 3 & 5 = 3 and 5 = 1, 3 | 5 = 3 or 5 = 7, 3 xor 5 = 6
//Error and Complementary Error Functions: erf(1) = 0.8427007929, erfc(1) = 0.1572992071

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

struct Exponent: BinaryExpression {
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

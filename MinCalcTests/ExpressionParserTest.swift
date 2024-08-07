import XCTest
import Foundation

@testable import MinCalc

class ComplexExpressionTests: XCTestCase {
    
    func testTokenization(_ expressionString: String, expected: [String]) {
        let parser = Parser(expression: expressionString)
        XCTAssertEqual(parser.tokens, expected)
    }
    
    func testExpression(_ expressionString: String, expected: Float, variables: [String: any MinCalc.Expression] = [:],  functions: [String : ([any MinCalc.Expression]) -> (any MinCalc.Expression)?] = [:]) {
        let parser = Parser(expression: expressionString)
        do {
            let expr = try parser.parse()
            XCTAssertEqual(expr.eval(variables, functions)!.asFloat(), expected, accuracy: 0.0001, "\(expr)")
        } catch {
            XCTFail("Failed to parse expression: \(expressionString): \(error)")
        }
    }
    
    func testTokenization() {
        testTokenization("2 + 3 * (5 - 1)", expected: ["2", "+", "3", "*", "(", "5", "-", "1", ")"])
        testTokenization("abs(-1.1) + sqrt(4) * 3", expected: ["abs", "(", "-", "1.1", ")", "+", "sqrt", "(", "4", ")", "*", "3"])
        testTokenization("2 * (8 + 1)", expected: ["2", "*", "(", "8", "+", "1", ")"])
        testTokenization("3 + 5 * (2 - 8) / 2", expected: ["3", "+", "5", "*", "(", "2", "-", "8", ")", "/", "2"])
        testTokenization("log(10) + ln(exp(1))", expected: ["log", "(", "10", ")", "+", "ln", "(", "exp", "(", "1", ")", ")"])
        testTokenization("3! + 2^3", expected: ["3", "!", "+", "2", "^", "3"])
        testTokenization("sind(90) + cosd(180) * tand(45)", expected: ["sind", "(", "90", ")", "+", "cosd", "(", "180", ")", "*", "tand", "(", "45", ")"])
        testTokenization("ceil(1.2) + floor(1.8) + round(1.5)", expected: ["ceil", "(", "1.2", ")", "+", "floor", "(", "1.8", ")", "+", "round", "(", "1.5", ")"])
        testTokenization("5 % 2 + 2 * 3", expected: ["5", "%", "2", "+", "2", "*", "3"])
    }
    
    func testComplexExpressions() {
        testExpression("2 + 3 * (5 - 1)", expected: 14)
        testExpression("abs(-1.1) + sqrt(4) * 3", expected: 7.1)
        testExpression("2 * (8 + 1)", expected: 18)
        testExpression("3 + 5 * (2 - 8) / 2", expected: -12)
        testExpression("log(10) + ln(exp(1))", expected: 2)
        testExpression("log(5 + 5)", expected: 1)
        testExpression("3! + 2^3", expected: 14)
        testExpression("sin(pi/2) + cos(pi) * tan(pi/4)", expected: 0, variables: ["pi": Literal(val: .pi)])
        testExpression("ceil(1.2) + floor(1.8) + round(1.5)", expected: 5)
        testExpression("5 % 2 + 2 * 3", expected: 7)
        testExpression("2 ^ 1 ^ 3", expected: 2)
    }
}

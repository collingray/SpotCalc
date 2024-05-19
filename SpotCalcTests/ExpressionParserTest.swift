import XCTest
import Foundation

@testable import SpotCalc

class ComplexExpressionTests: XCTestCase {
    
    func testTokenization(_ expressionString: String, expected: [String]) {
        let parser = Parser(expression: expressionString)
        XCTAssertEqual(parser.tokens, expected)
    }
    
    func testExpression(_ expressionString: String, expected: Float, variables: [String: Float] = [:]) {
        let parser = Parser(expression: expressionString)
        do {
            let expr = try parser.parse()
            XCTAssertEqual(expr.eval(variables), expected, "\(expr)")
        } catch {
            XCTFail("Failed to parse expression: \(expressionString)")
        }
    }
    
    func testTokenization() {
        testTokenization("2 + 3 * (5 - 1)", expected: ["2", "+", "3", "*", "(", "5", "-", "1", ")"])
        testTokenization("abs(-1.1) + sqrt(4) * 3", expected: ["abs", "(", "-1.1", ")", "+", "sqrt", "(", "4", ")", "*", "3"])
        testTokenization("2 * (8 + 1)", expected: ["2", "*", "(", "8", "+", "1", ")"])
        testTokenization("3 + 5 * (2 - 8) / 2", expected: ["3", "+", "5", "*", "(", "2", "-", "8", ")", "/", "2"])
        testTokenization("log(10) + ln(exp(1))", expected: ["log", "(", "10", ")", "+", "ln", "(", "exp", "(", "1", ")", ")"])
        testTokenization("3! + 2^3", expected: ["3", "!", "+", "2", "^", "3"])
        testTokenization("sind(90) + cosd(180) * tand(45)", expected: ["sind", "(", "90", ")", "+", "cosd", "(", "180", ")", "*", "tand", "(", "45", ")"])
        testTokenization("ceil(1.2) + floor(1.8) + round(1.5)", expected: ["ceil", "(", "1.2", ")", "+", "floor", "(", "1.8", ")", "+", "round", "(", "1.5", ")"])
        testTokenization("erf(1) + erfc(1)", expected: ["erf", "(", "1", ")", "+", "erfc", "(", "1", ")"])
        testTokenization("5 % 2 + 2 * 3", expected: ["5", "%", "2", "+", "2", "*", "3"])
    }
    
    func testComplexExpressions() {
        testExpression("2 + 3 * (5 - 1)", expected: 14)
        testExpression("abs(-1.1) + sqrt(4) * 3", expected: 7.1)
        testExpression("2 * (8 + 1)", expected: 18)
        testExpression("3 + 5 * (2 - 8) / 2", expected: -12)
        testExpression("log(10) + ln(exp(1))", expected: 2)
//        testExpression("3! + 2^3", expected: 14)
//        testExpression("sind(90) + cosd(180) * tand(45)", expected: 0)
        testExpression("ceil(1.2) + floor(1.8) + round(1.5)", expected: 5)
        testExpression("erf(1) + erfc(1)", expected: 1)
        testExpression("5 % 2 + 2 * 3", expected: 7)
        testExpression("2 ^ 1 ^ 3", expected: 2)
    }
}

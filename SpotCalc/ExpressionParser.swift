import Foundation

enum ParserError: Error {
    case invalidSyntax
}

class Parser {
    var tokens: [String]
    private var index = 0

    init(expression: String) {
        self.tokens = Parser.tokenize(expression)
    }

    static func tokenize(_ expression: String) -> [String] {
        
        let pattern = """
        (?x)
        (-?\\d+(\\.\\d+)?) |     # Numbers (including negative and decimals)
        ([\\+\\-\\*/\\^=]) |     # Basic operators (+, -, *, /, ^, =)
        ([\\(\\)]) |             # Parentheses
        \\b(abs|fabs|log|ln|exp|sqrt|cbrt|sin|cos|tan|sinh|cosh|tanh|arcsin|arccos|arctan|arcsinh|arccosh|arctanh|ceil|floor|round|erf|erfc)\\b | # Functions
        (!) |                    # Factorial
        (%|\\bmod\\b) |          # Modulus
        \\b(mph|hours|miles|km|kilometers|deg|degrees|radians|%)\\b | # Units and percentage
        (\\)) |                  # Implied multiplication (e.g., 2(8+1))
        ([a-zA-Z]+)              # Variables (e.g., e, pi)
        """

        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .allowCommentsAndWhitespace])
        let nsString = expression as NSString
        let results = regex.matches(in: expression, range: NSRange(location: 0, length: nsString.length))
        return results.map { nsString.substring(with: $0.range) }
    }

    func parse() throws -> Expression {
        return try parseExpression()
    }

    private func parseExpression() throws -> Expression {
        var expr = try parseTerm()

        while let token = currentToken, token == "+" || token == "-" {
            advance()
            let rhs = try parseTerm()
            if token == "+" {
                expr = Add(x: expr, y: rhs)
            } else if token == "-" {
                expr = Subtract(x: expr, y: rhs)
            }
        }

        return expr
    }

    private func parseTerm() throws -> Expression {
        var term = try parseFactor()

        while let token = currentToken, token == "*" || token == "/" {
            advance()
            let rhs = try parseFactor()
            if token == "*" {
                term = Multiply(x: term, y: rhs)
            } else if token == "/" {
                term = Divide(x: term, y: rhs)
            }
        }

        return term
    }

    private func parseFactor() throws -> Expression {
        if let token = currentToken {
            if let number = Float(token) {
                advance()
                return Literal(val: number)
            } else if token == "(" {
                advance()
                let expr = try parseExpression()
                guard currentToken == ")" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                return expr
            } else if token == "abs" {
                advance()
                guard currentToken == "(" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                let expr = try parseExpression()
                guard currentToken == ")" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                return AbsoluteValue(x: expr)
            } else if token == "sqrt" {
                advance()
                guard currentToken == "(" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                let expr = try parseExpression()
                guard currentToken == ")" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                return SquareRoot(x: expr)
            } else if token == "cbrt" {
                advance()
                guard currentToken == "(" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                let expr = try parseExpression()
                guard currentToken == ")" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                return CubeRoot(x: expr)
            } else {
                let variable = token
                advance()
                return Variable(name: variable)
            }
        }

        throw ParserError.invalidSyntax
    }

    private var currentToken: String? {
        return index < tokens.count ? tokens[index] : nil
    }

    private func advance() {
        index += 1
    }
}

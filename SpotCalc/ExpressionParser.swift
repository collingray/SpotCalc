import Foundation
import BigDecimal

enum ParserError: Error {
    case invalidSyntax
}

class Parser {
    var tokens: [String]
    private var index = 0

    init(expression: String) {
        self.tokens = Parser.tokenize(expression)
        print("tokens: \(self.tokens)")
    }

    static func tokenize(_ expression: String) -> [String] {
        
        let pattern = """
        (?x)
        (-?\\d+(\\.\\d+)?(e(-|\\+)?\\d+)?) | # Numbers (including negatives, decimals, and exponential notation)
        (\\*\\*) |               # Alternate power
        (//) |                   # Floor divide
        ([\\+\\-\\*/\\^=]) |     # Basic operators (+, -, *, /, ^, =)
        ([\\(\\)]) |             # Parentheses
        \\b(abs|fabs|log|ln|exp|sqrt|cbrt|sin|cos|tan|sinh|cosh|tanh|arcsin|arccos|arctan|arcsinh|arccosh|arctanh|ceil|floor|round)\\b | # Functions
        (!) |                    # Factorial
        (%|\\bmod\\b) |          # Modulus
        \\b(mph|hours|miles|km|kilometers|deg|degrees|radians|%)\\b | # Units and percentage
        (\\)) |                  # Implied multiplication (e.g., 2(8+1))
        ([a-zA-Z]\\w*)           # Variables (e.g., e, pi)
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
        return try parseTerm()
    }

    static let termSymbols = ["+", "-"]
    private func parseTerm() throws -> Expression {
        var term = try parseFactor()

        while let token = currentToken, Parser.termSymbols.contains(token) {
            advance()
            let rhs = try parseFactor()
            
            switch token {
            case "+": term = Add(x: term, y: rhs)
            case "-": term = Subtract(x: term, y: rhs)
            default: ()
            }
        }

        return term
    }

    static let factorSymbols = ["*", "/", "%", "//"]
    private func parseFactor() throws -> Expression {
        var factor = try parsePostfix()

        while let token = currentToken, Parser.factorSymbols.contains(token) {
            advance()
            guard let rhs = try? parsePostfix() else {
                throw ParserError.invalidSyntax
            }
            
            switch token {
            case "*": factor = Multiply(x: factor, y: rhs)
            case "/": factor = Divide(x: factor, y: rhs)
            case "%": factor = Modulus(x: factor, y: rhs)
            case "//": factor = FloorDivide(x: factor, y: rhs)
            default: ()
            }
        }

        return factor
    }
    
    
    static let postfixSymbols = ["!"]
    private func parsePostfix() throws -> Expression {
        var postfix = try parsePrefix()

        while let token = currentToken, Parser.postfixSymbols.contains(token) {
            advance()
            
            switch token {
            case "!": postfix = Factorial(x: postfix)
            default: ()
            }
        }

        return postfix
    }
    
    static let prefixSymbols = ["+", "-"]
    private func parsePrefix() throws -> Expression {
        if let token = currentToken, Parser.prefixSymbols.contains(token) {
            advance()
            let rhs = try parsePrefix()
            
            switch token {
            case "+": return UnaryPlus(x: rhs)
            case "-": return UnaryMinus(x: rhs)
            default: ()
            }
        }

        return try parseExponent()
    }
    
    
    static let exponentSymbols = ["^", "**"]
    private func parseExponent() throws -> Expression {
        return try parseExponentRecursively()
    }

    private func parseExponentRecursively() throws -> Expression {
        var exponent = try parseAtom()

        if let token = currentToken, Parser.exponentSymbols.contains(token) {
            advance()
            let rhs = try parseExponentRecursively()
            
            switch token {
            case "^": exponent = Exponent(x: exponent, y: rhs)
            case "**": exponent = Exponent(x: exponent, y: rhs)
            default: ()
            }
        }

        return exponent
    }
    
    static let functionSymbols = ["abs", "log", "ln", "exp", "sqrt", "cbrt", "sin", "cos", "tan", "arcsin", "arccos", "arctan", "sinh", "cosh", "tanh", "arcsinh", "arccosh", "arctanh", "ceil", "floor", "round"]
    static let symbolRegex = /[a-zA-Z]\w*/
    private func parseAtom() throws -> Expression {
        if let token = currentToken {
            let number = BigDecimal(token)
            
            if !number.isNaN {
                advance()
                return Literal(val: number)
            } else if token == "(" {
                advance()
                let expr = try parseExpression()
                guard currentToken == ")" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                return Grouping(x: expr)
            } else if Parser.functionSymbols.contains(token) {
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
                
                switch token {
                case "abs": return AbsoluteValue(x: expr)
                case "log": return LogarithmBase10(x: expr)
                case "ln": return NaturalLogarithm(x: expr)
                case "exp": return Exponential(x: expr)
                case "sqrt": return SquareRoot(x: expr)
                case "cbrt": return CubeRoot(x: expr)
                case "sin": return Sine(x: expr)
                case "cos": return Cosine(x: expr)
                case "tan": return Tangent(x: expr)
                case "arcsin": return ArcSine(x: expr)
                case "arccos": return ArcCosine(x: expr)
                case "arctan": return ArcTangent(x: expr)
                case "sinh": return Sinh(x: expr)
                case "cosh": return Cosh(x: expr)
                case "tanh": return Tanh(x: expr)
                case "arcsinh": return ArcSinh(x: expr)
                case "arccosh": return ArcCosh(x: expr)
                case "arctanh": return ArcTanh(x: expr)
                case "ceil": return Ceiling(x: expr)
                case "floor": return Floor(x: expr)
                case "round": return Round(x: expr)
                default: ()
                }
            } else if try Parser.symbolRegex.wholeMatch(in: token) != nil {
                advance()
                guard currentToken == "(" else {
                    return Variable(name: token)
                }
                advance()
                var exprs: [Expression] = [try parseExpression()]
                
                while let token = currentToken, token == "," {
                    advance()
                    exprs.append(try parseExpression())
                }
                
                guard currentToken == ")" else {
                    throw ParserError.invalidSyntax
                }
                advance()
                
                return Function(name: token, args: exprs)
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

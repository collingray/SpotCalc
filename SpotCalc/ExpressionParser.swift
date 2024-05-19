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

    static let factorSymbols = ["*", "x", "/", "%"]
    private func parseFactor() throws -> Expression {
        var factor = try parsePrefix() // todo

        while let token = currentToken, Parser.factorSymbols.contains(token) {
            advance()
            let rhs = try parsePrefix()
            
            switch token {
            case "*": factor = Multiply(x: factor, y: rhs)
            case "x": factor = Multiply(x: factor, y: rhs)
            case "/": factor = Divide(x: factor, y: rhs)
            case "%": factor = Modulus(x: factor, y: rhs)
            default: ()
            }
        }

        return factor
    }
    
    
//    static let postfixSymbols = ["!"]
//    private func parsePostfix() throws -> Expression { // todo
//        var postfix = try parsePrefix()
//
//        while let token = currentToken, Parser.postfixSymbols.contains(token) {
//            advance()
//            let rhs = try parsePrefix()
//            
//            switch token {
//            case "!": postfix = Factorial(x: postfix)
//            default: ()
//            }
//        }
//
//        return postfix
//    }
    
    static let prefixSymbols = ["+", "-"]
    private func parsePrefix() throws -> Expression {
        if let token = currentToken, Parser.prefixSymbols.contains(token) {
            advance()
            let rhs = try parseExponent()
            
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
        var exponent = try parseFunction()

        if let token = currentToken, Parser.exponentSymbols.contains(token) {
            advance()
            let rhs = try parseExponentRecursively()
            
            switch token {
            case "^": exponent = CaretExponent(x: exponent, y: rhs)
            case "**": exponent = StarStarExponent(x: exponent, y: rhs)
            default: ()
            }
        }

        return exponent
    }
    
    static let functionSymbols = ["abs", "log", "ln", "exp", "sqrt", "cbrt", "sin", "cos", "tan", "arcsin", "arccos", "arctan", "sinh", "cosh", "tanh", "arcsinh", "arccosh", "arctanh", "ceil", "floor", "round", "erf", "erfc"]
    private func parseFunction() throws -> Expression {
        if let token = currentToken, Parser.functionSymbols.contains(token) {
            advance()
            guard currentToken == "(" else {
                throw ParserError.invalidSyntax
            }
            advance()
            let function = try parseFunction()
            guard currentToken == ")" else {
                throw ParserError.invalidSyntax
            }
            advance()
            
            switch token {
            case "abs": return AbsoluteValue(x: function)
            case "log": return LogarithmBase10(x: function)
            case "ln": return NaturalLogarithm(x: function)
            case "exp": return Exponential(x: function)
            case "sqrt": return SquareRoot(x: function)
            case "cbrt": return CubeRoot(x: function)
            case "sin": return Sine(x: function)
            case "cos": return Cosine(x: function)
            case "tan": return Tangent(x: function)
            case "arcsin": return ArcSine(x: function)
            case "arccos": return ArcCosine(x: function)
            case "arctan": return ArcTangent(x: function)
            case "sinh": return Sinh(x: function)
            case "cosh": return Cosh(x: function)
            case "tanh": return Tanh(x: function)
            case "arcsinh": return ArcSinh(x: function)
            case "arccosh": return ArcCosh(x: function)
            case "arctanh": return ArcTanh(x: function)
            case "ceil": return Ceiling(x: function)
            case "floor": return Floor(x: function)
            case "round": return Round(x: function)
            case "erf": return Erf(x: function)
            case "erfc": return Erfc(x: function)
            default: ()
            }
        }

        return try parseAtom()
    }
    
    static let variableRegex = /[a-zA-Z]\w*/
    private func parseAtom() throws -> Expression {
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
                return Grouping(x: expr)
            } else if try Parser.variableRegex.wholeMatch(in: token) != nil {
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

//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Oliver Kovacs on 03/03/15.
//  Copyright (c) 2015 Oliver Kovacs. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    private enum Op: Printable {
        case Operand(Double)
        case Constant(String, Double)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperarion(String, (Double, Double) -> Double)
        case Variable(String, String -> Double?)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand): return "\(operand)"
                case .Constant(let symbol, _): return symbol
                case .UnaryOperation(let symbol, _): return symbol
                case .BinaryOperarion(let symbol, _): return symbol
                case .Variable(let symbol, _): return symbol
                }
            }
        }
    }
    
    private var opStack = [Op]()
    private var knownOps = [String: Op]()

    var variableValues = [String: Double]()
    
    typealias PropertyList = AnyObject
    var program: PropertyList {
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    init() {
        func pushStack(op: Op) {
            knownOps[op.description] = op
        }
        pushStack(Op.BinaryOperarion("+", +))
        pushStack(Op.BinaryOperarion("×", *))
        pushStack(Op.BinaryOperarion("−", { $1 - $0 }))
        pushStack(Op.BinaryOperarion("÷", { $1 / $0 }))
        pushStack(Op.UnaryOperation("√", sqrt))
        pushStack(Op.UnaryOperation("sin", sin))
        pushStack(Op.UnaryOperation("cos", cos))
        pushStack(Op.UnaryOperation("±", { $0 * -1 }))
        pushStack(Op.Constant("π", M_PI))
    }
    
    private func evaluate(stack: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !stack.isEmpty {
            var remainingOps = stack
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .Variable(let symbol, let operation):
                return (operation(symbol), remainingOps)
            case .Constant(_, let operand):
                return (operand, remainingOps)
            case .UnaryOperation(_, let operation):
                let opEvaluation = evaluate(remainingOps)
                if let result = opEvaluation.result {
                    return (operation(result), opEvaluation.remainingOps)
                }
            case .BinaryOperarion(_, let operation):
                let opEvaluation = evaluate(remainingOps)
                if let result = opEvaluation.result {
                    let op2Evaluation = evaluate(opEvaluation.remainingOps)
                    if let result2 = op2Evaluation.result {
                        return (operation(result, result2), op2Evaluation.remainingOps)
                    }
                }
            }
        }
        return (nil, stack)
    }
    
    func evaluate() -> Double? {
        let (result, _) = evaluate(opStack)
        return result
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol, { self.variableValues[$0] }))
        return evaluate()
    }
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluate()
    }
    
    private func humanReadableStack(stack: [Op]) -> (result: String?, remainingOps: [Op]) {
        if (!stack.isEmpty) {
            var remainingOps = stack
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return ("\(operand)", remainingOps)
            case .Constant(let symbol, _):
                return (symbol, remainingOps)
            case .UnaryOperation(let symbol, _):
                let opEvaluation = humanReadableStack(remainingOps)
                if let result = opEvaluation.result {
                    return (symbol + "(" + result + ")", remainingOps)
                }
            case .BinaryOperarion(let symbol, _):
                let opEvaluation = humanReadableStack(remainingOps)
                if let result = opEvaluation.result {
                    let op2Evaluation = humanReadableStack(opEvaluation.remainingOps)
                    if let result2 = op2Evaluation.result {
                        return ("(" + result2 + " " + symbol + " " + result + ")", op2Evaluation.remainingOps)
                    }
                }
            case .Variable(let symbol, _):
                return (symbol, remainingOps)
            }
        }
        return ("0", stack)
    }
    
    func humanReadableStack() -> String? {
        let (result, _) = humanReadableStack(opStack)
        return result
    }
    
    func clearStack() {
        opStack.removeAll(keepCapacity: true)
    }
    
    func clearVariables() {
        variableValues.removeAll(keepCapacity: true)
    }
    
    func removeLast() {
        opStack.removeLast()
    }
}
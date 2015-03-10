//
//  ViewController.swift
//  Calculator
//
//  Created by Oliver Kovacs on 28/02/15.
//  Copyright (c) 2015 Oliver Kovacs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {


    @IBOutlet weak var display: UILabel!
    
    @IBOutlet weak var history: UILabel!
    
    var brain = CalculatorBrain()
    
    var userIsTyping = false
    
    var displayValue: Double? {
        get {
            if let text = display.text {
                return NSNumberFormatter().numberFromString(text)?.doubleValue
            }
            return nil
        }
        set {
            display.text = "\(newValue ?? 0)"
        }
    }

    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        let text = display.text!
        
        // TODO: Simplify...
        if userIsTyping {
            if digit == "." {
                if text.rangeOfString(".") == nil {
                    display.text = text + "."
                }
            } else {
                display.text = text == "0" ? digit : text + digit
            }
        } else {
            display.text = (digit == ".") ? "0." : digit
            userIsTyping = true
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        if userIsTyping {
            enter()
        }
        
        if let operand = sender.currentTitle {
            displayValue = brain.performOperation(operand)
            userIsTyping = false;
            history.text = brain.humanReadableStack()
        }
    }

    @IBAction func enter() {
        userIsTyping = false;
        if let value = displayValue {
            displayValue = brain.pushOperand(value)
        }
        history.text = brain.humanReadableStack()
    }
    
    @IBAction func flipSign(sender: UIButton) {
        if userIsTyping {
            // TODO: Fix floating point issue.
            if let value = displayValue {
                displayValue = value * -1
            }
        } else {
            operate(sender)
        }
    }
    
    
    @IBAction func replaceVariable(sender: UIButton) {
        if userIsTyping { enter() }
        displayValue = brain.pushOperand("M")
    }
    
    @IBAction func setVariable(sender: UIButton) {
        if let value = displayValue {
            brain.variableValues["M"] = value
            userIsTyping = false
            displayValue = brain.evaluate()
        }
    }
    
    @IBAction func clear() {
        display.text = "0"
        history.text = ""
        brain.clearStack()
        userIsTyping = false
    }
    
    @IBAction func backspace() {
        if userIsTyping {
            if let text = display.text {
                display.text = countElements(text) > 1 ? dropLast(text) : "0"
            }
        }
    }
}
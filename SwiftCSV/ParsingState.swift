//
//  ParsingState.swift
//  SwiftCSV
//
//  Created by Christian Tietze on 25/10/16.
//  Copyright © 2016 Naoto Kaneko. All rights reserved.
//

fileprivate extension Character {
    var isNewline: Bool {
        return self == "\n" || self == "\r\n" || self == "\r"
    }
}

/// State machine of parsing CSV contents character by character.
struct ParsingState {

    private(set) var atStart = true
    private(set) var parsingField = false
    private(set) var parsingQuotes = false
    private(set) var innerQuotes = false

    let delimiter: Character
    let finishRow: () -> Void
    let appendChar: (Character) -> Void
    let finishField: () -> Void

    init(delimiter: Character,
         finishRow: @escaping () -> Void,
         appendChar: @escaping (Character) -> Void,
         finishField: @escaping () -> Void) {

        self.delimiter = delimiter
        self.finishRow = finishRow
        self.appendChar = appendChar
        self.finishField = finishField
    }

    mutating func change(_ char: Character) {
        if atStart {
            if char == "\"" {
                atStart = false
                parsingQuotes = true
            } else if char == delimiter {
                finishField()
            } else if char.isNewline {
                finishRow()
            } else {
                parsingField = true
                atStart = false
                appendChar(char)
            }
        } else if parsingField {
            if innerQuotes {
                if char == "\"" {
                    appendChar(char)
                    innerQuotes = false
                } else {
                    fatalError("Can't have non-quote here: \(char)")
                }
            } else {
                if char == "\"" {
                    innerQuotes = true
                } else if char == delimiter {
                    atStart = true
                    parsingField = false
                    innerQuotes = false
                    finishField()
                } else if char.isNewline {
                    atStart = true
                    parsingField = false
                    innerQuotes = false
                    finishRow()
                } else {
                    appendChar(char)
                }
            }
        } else if parsingQuotes {
            if innerQuotes {
                if char == "\"" {
                    appendChar(char)
                    innerQuotes = false
                } else if char == delimiter {
                    atStart = true
                    parsingField = false
                    innerQuotes = false
                    finishField()
                } else if char.isNewline {
                    atStart = true
                    parsingQuotes = false
                    innerQuotes = false
                    finishRow()
                } else {
                    fatalError("Can't have non-quote here: \(char)")
                }
            } else {
                if char == "\"" {
                    innerQuotes = true
                } else {
                    appendChar(char)
                }
            }
        } else {
            fatalError("me_irl")
        }
    }
}

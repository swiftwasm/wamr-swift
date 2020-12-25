class AsmParser {
    let contents: String
    var output: String

    var cursor: String.Index
    var startComment: Bool {
        contents[cursor] == "/" && contents[contents.index(after: cursor)] == "*"
    }
    var endComment: Bool {
        contents[cursor] == "*" && contents[contents.index(after: cursor)] == "/"
    }
    
    var isMacroLine: Bool {
        contents[cursor] == "#"
    }

    init(contents: String) {
        self.contents = contents
        self.cursor = contents.startIndex
        self.output = ""
    }

    func advanceCursor(offset: Int = 1) {
        cursor = contents.index(cursor, offsetBy: offset)
    }
    func writeOutput<S: StringProtocol>(_ outContent: S) {
        output += outContent
    }
    func writeOutput(_ outContent: Character) {
        writeOutput(String(outContent))
    }

    func parse() {
        while cursor < contents.endIndex {
            if isMacroLine {
                while !contents[cursor].isNewline {
                    writeOutput(contents[cursor])
                    advanceCursor(offset: 1)
                }
                writeOutput(contents[cursor])
                advanceCursor(offset: 1) // Skip '\n'
                continue
            } else if startComment {
                while !endComment {
                    writeOutput(contents[cursor])
                    advanceCursor(offset: 1)
                }
                writeOutput(contents[cursor..<contents.index(cursor, offsetBy: 2)])
                advanceCursor(offset: 2) // Skip '*/'
                continue
            } else if contents[cursor].isNewline {
                advanceCursor(offset: 1)
                writeOutput("\n")
            } else {
                writeOutput("\"")
                while !contents[cursor].isNewline && !startComment {
                    writeOutput(contents[cursor])
                    advanceCursor(offset: 1)
                }
                writeOutput("\\n\"")
                if startComment { continue }
                advanceCursor(offset: 1)
                writeOutput("\n")
            }
        }
    }
}

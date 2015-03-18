-- For All Indents And Purposes
local revision = 17
-- Original author: kristofer.karlsson@gmail.com
-- IUP adaptation: pixel@grumpycoder.net

-- For All Indents And Purposes -
-- a indentation + syntax highlighting library
-- All valid lua code should be processed correctly.

-- Usage
--------
-- hook the textboxes that you want to have indentation like this:
-- IndentationLib.enable(editbox [, colorTable [, tabWidth] ])
-- if you don't select a color table, it will use the default.
-- Read through this code for further usage help.
-- (The documentation IS the code)

if not IndentationLib then
    IndentationLib = {}
end

if not IndentationLib.revision or revision > IndentationLib.revision then
    local lib = IndentationLib
    lib.revision = revision
    
    local stringlen = string.len
    local stringformat = string.format
    local stringfind = string.find
    local stringsub = string.sub
    local stringbyte = string.byte
    local stringchar = string.char
    local stringrep = string.rep
    local stringgsub = string.gsub
    
    local workingTable = {}
    local workingTable2 = {}
    local function tableclear(t)
        for k in next,t do
            t[k] = nil
        end
    end
    
    local function stringinsert(s, pos, insertStr)
        return stringsub(s, 1, pos) .. insertStr .. stringsub(s, pos + 1)
    end
    lib.stringinsert = stringinsert
    
    local function stringdelete(s, pos1, pos2)
        return stringsub(s, 1, pos1 - 1) .. stringsub(s, pos2 + 1)
    end
    lib.stringdelete = stringdelete
    
    -- token types
    local tokens = {}
    lib.tokens = tokens
    
    tokens.TOKEN_UNKNOWN = 0
    tokens.TOKEN_NUMBER = 1
    tokens.TOKEN_LINEBREAK = 2
    tokens.TOKEN_WHITESPACE = 3
    tokens.TOKEN_IDENTIFIER = 4
    tokens.TOKEN_ASSIGNMENT = 5
    tokens.TOKEN_EQUALITY = 6
    tokens.TOKEN_MINUS = 7
    tokens.TOKEN_COMMENT_SHORT = 8
    tokens.TOKEN_COMMENT_LONG = 9
    tokens.TOKEN_STRING = 10
    tokens.TOKEN_LEFTBRACKET = 11
    tokens.TOKEN_PERIOD = 12
    tokens.TOKEN_DOUBLEPERIOD = 13
    tokens.TOKEN_TRIPLEPERIOD = 14
    tokens.TOKEN_LTE = 15
    tokens.TOKEN_LT = 16
    tokens.TOKEN_GTE = 17
    tokens.TOKEN_GT = 18
    tokens.TOKEN_NOTEQUAL = 19
    tokens.TOKEN_COMMA = 20
    tokens.TOKEN_SEMICOLON = 21
    tokens.TOKEN_COLON = 22
    tokens.TOKEN_LEFTPAREN = 23
    tokens.TOKEN_RIGHTPAREN = 24
    tokens.TOKEN_PLUS = 25
    tokens.TOKEN_SLASH = 27
    tokens.TOKEN_LEFTWING = 28
    tokens.TOKEN_RIGHTWING = 29
    tokens.TOKEN_CIRCUMFLEX = 30
    tokens.TOKEN_ASTERISK = 31
    tokens.TOKEN_RIGHTBRACKET = 32
    tokens.TOKEN_KEYWORD = 33
    tokens.TOKEN_SPECIAL = 34
    tokens.TOKEN_VERTICAL = 35
    tokens.TOKEN_TILDE = 36
    tokens.TOKEN_HASH = 39
    tokens.TOKEN_PERCENT = 40
    
    
    -- ascii codes
    local bytes = {}
    lib.bytes = bytes
    bytes.BYTE_LINEBREAK_UNIX = stringbyte("\n")
    bytes.BYTE_LINEBREAK_MAC = stringbyte("\r")
    bytes.BYTE_SINGLE_QUOTE = stringbyte("'")
    bytes.BYTE_DOUBLE_QUOTE = stringbyte('"')
    bytes.BYTE_0 = stringbyte("0")
    bytes.BYTE_9 = stringbyte("9")
    bytes.BYTE_PERIOD = stringbyte(".")
    bytes.BYTE_SPACE = stringbyte(" ")
    bytes.BYTE_TAB = stringbyte("\t")
    bytes.BYTE_E = stringbyte("E")
    bytes.BYTE_e = stringbyte("e")
    bytes.BYTE_MINUS = stringbyte("-")
    bytes.BYTE_EQUALS = stringbyte("=")
    bytes.BYTE_LEFTBRACKET = stringbyte("[")
    bytes.BYTE_RIGHTBRACKET = stringbyte("]")
    bytes.BYTE_BACKSLASH = stringbyte("\\")
    bytes.BYTE_COMMA = stringbyte(",")
    bytes.BYTE_SEMICOLON = stringbyte(";")
    bytes.BYTE_COLON = stringbyte(":")
    bytes.BYTE_LEFTPAREN = stringbyte("(")
    bytes.BYTE_RIGHTPAREN = stringbyte(")")
    bytes.BYTE_TILDE = stringbyte("~")
    bytes.BYTE_PLUS = stringbyte("+")
    bytes.BYTE_SLASH = stringbyte("/")
    bytes.BYTE_LEFTWING = stringbyte("{")
    bytes.BYTE_RIGHTWING = stringbyte("}")
    bytes.BYTE_CIRCUMFLEX = stringbyte("^")
    bytes.BYTE_ASTERISK = stringbyte("*")
    bytes.BYTE_LESSTHAN = stringbyte("<")
    bytes.BYTE_GREATERTHAN = stringbyte(">")
    bytes.BYTE_HASH = stringbyte("#")
    bytes.BYTE_PERCENT = stringbyte("%")
    
    
    local linebreakCharacters = {}
    lib.linebreakCharacters = linebreakCharacters
    linebreakCharacters[bytes.BYTE_LINEBREAK_UNIX] = 1
    linebreakCharacters[bytes.BYTE_LINEBREAK_MAC] = 1
    
    local whitespaceCharacters = {}
    lib.whitespaceCharacters = whitespaceCharacters
    whitespaceCharacters[bytes.BYTE_SPACE] = 1
    whitespaceCharacters[bytes.BYTE_TAB] = 1
    
    local specialCharacters = {}
    lib.specialCharacters = specialCharacters
    specialCharacters[bytes.BYTE_PERIOD] = -1
    specialCharacters[bytes.BYTE_LESSTHAN] = -1
    specialCharacters[bytes.BYTE_GREATERTHAN] = -1
    specialCharacters[bytes.BYTE_LEFTBRACKET] = -1
    specialCharacters[bytes.BYTE_EQUALS] = -1
    specialCharacters[bytes.BYTE_MINUS] = -1
    specialCharacters[bytes.BYTE_SINGLE_QUOTE] = -1
    specialCharacters[bytes.BYTE_DOUBLE_QUOTE] = -1
    specialCharacters[bytes.BYTE_TILDE] = -1
    specialCharacters[bytes.BYTE_RIGHTBRACKET] = tokens.TOKEN_RIGHTBRACKET
    specialCharacters[bytes.BYTE_COMMA] = tokens.TOKEN_COMMA
    specialCharacters[bytes.BYTE_COLON] = tokens.TOKEN_COLON
    specialCharacters[bytes.BYTE_SEMICOLON] = tokens.TOKEN_SEMICOLON
    specialCharacters[bytes.BYTE_LEFTPAREN] = tokens.TOKEN_LEFTPAREN
    specialCharacters[bytes.BYTE_RIGHTPAREN] = tokens.TOKEN_RIGHTPAREN
    specialCharacters[bytes.BYTE_PLUS] = tokens.TOKEN_PLUS
    specialCharacters[bytes.BYTE_SLASH] = tokens.TOKEN_SLASH
    specialCharacters[bytes.BYTE_LEFTWING] = tokens.TOKEN_LEFTWING
    specialCharacters[bytes.BYTE_RIGHTWING] = tokens.TOKEN_RIGHTWING
    specialCharacters[bytes.BYTE_CIRCUMFLEX] = tokens.TOKEN_CIRCUMFLEX
    specialCharacters[bytes.BYTE_ASTERISK] = tokens.TOKEN_ASTERISK
    specialCharacters[bytes.BYTE_HASH] = tokens.TOKEN_HASH
    specialCharacters[bytes.BYTE_PERCENT] = tokens.TOKEN_PERCENT
    
    local function nextNumberExponentPartInt(text, pos)
        while true do
            local byte = stringbyte(text, pos)
            if not byte then
                return tokens.TOKEN_NUMBER, pos
            end
            
            if byte >= bytes.BYTE_0 and byte <= bytes.BYTE_9 then	
                pos = pos + 1
            else
                return tokens.TOKEN_NUMBER, pos 
            end
        end
    end
    
    local function nextNumberExponentPart(text, pos)
        local byte = stringbyte(text, pos)
        if not byte then
            return tokens.TOKEN_NUMBER, pos
        end
        
        if byte == bytes.BYTE_MINUS then
            -- handle this case: a = 1.2e-- some comment
            -- i decide to let 1.2e be parsed as a a number
            byte = stringbyte(text, pos + 1)
            if byte == bytes.BYTE_MINUS then
                return tokens.TOKEN_NUMBER, pos
            end
            return nextNumberExponentPartInt(text, pos + 1)
        end
        
        return nextNumberExponentPartInt(text, pos)
    end
    
    local function nextNumberFractionPart(text, pos)
        while true do
            local byte = stringbyte(text, pos)
            if not byte then
                return tokens.TOKEN_NUMBER, pos
            end
            
            if byte >= bytes.BYTE_0 and byte <= bytes.BYTE_9 then	
                pos = pos + 1
            elseif byte == bytes.BYTE_E or byte == bytes.BYTE_e then
                return nextNumberExponentPart(text, pos + 1)
            else
                return tokens.TOKEN_NUMBER, pos 
            end
        end
    end
    
    local function nextNumberIntPart(text, pos)
        while true do
            local byte = stringbyte(text, pos)
            if not byte then
                return tokens.TOKEN_NUMBER, pos
            end
            
            if byte >= bytes.BYTE_0 and byte <= bytes.BYTE_9 then	
                pos = pos + 1
            elseif byte == bytes.BYTE_PERIOD then
                return nextNumberFractionPart(text, pos + 1)
            elseif byte == bytes.BYTE_E or byte == bytes.BYTE_e then
                return nextNumberExponentPart(text, pos + 1)
            else
                return tokens.TOKEN_NUMBER, pos
            end
        end
    end
    
    local function nextIdentifier(text, pos)
        while true do
            local byte = stringbyte(text, pos)
            
            if not byte or
            linebreakCharacters[byte] or
            whitespaceCharacters[byte] or
            specialCharacters[byte] then
                return tokens.TOKEN_IDENTIFIER, pos
            end
            pos = pos + 1
        end
    end
    
    -- returns false or: true, nextPos, equalsCount
    local function isBracketStringNext(text, pos)
        local byte = stringbyte(text, pos)
        if byte == bytes.BYTE_LEFTBRACKET then
            local pos2 = pos + 1
            byte = stringbyte(text, pos2)
            while byte == bytes.BYTE_EQUALS do
                pos2 = pos2 + 1
                byte = stringbyte(text, pos2)
            end
            if byte == bytes.BYTE_LEFTBRACKET then
                return true, pos2 + 1, (pos2 - 1) - pos
            else
                return false
            end
        else
            return false
        end
    end
    
    
    -- Already parsed the [==[ part when get here
    local function nextBracketString(text, pos, equalsCount)
        local state = 0
        while true do
            local byte = stringbyte(text, pos)
            if not byte then
                return tokens.TOKEN_STRING, pos
            end
            
            if byte == bytes.BYTE_RIGHTBRACKET then
                if state == 0 then
                    state = 1
                elseif state == equalsCount + 1 then
                    return tokens.TOKEN_STRING, pos + 1
                else
                    state = 0
                end
            elseif byte == bytes.BYTE_EQUALS then
                if state > 0 then
                    state = state + 1
                end
            else
                state = 0
            end
            pos = pos + 1
        end
    end
    
    local function nextComment(text, pos)
        -- When we get here we have already parsed the "--"
        -- Check for long comment
        local isBracketString, nextPos, equalsCount = isBracketStringNext(text, pos)
        if isBracketString then
            local tokenType, nextPos2 = nextBracketString(text, nextPos, equalsCount)
            return tokens.TOKEN_COMMENT_LONG, nextPos2
        end
        
        local byte = stringbyte(text, pos)
        
        -- Short comment, find the first linebreak
        while true do
            byte = stringbyte(text, pos)
            if not byte then
                return tokens.TOKEN_COMMENT_SHORT, pos
            end
            if linebreakCharacters[byte] then
                return tokens.TOKEN_COMMENT_SHORT, pos
            end
            pos = pos + 1
        end
    end
    
    local function nextString(text, pos, character)
        local even = true
        while true do
            local byte = stringbyte(text, pos)
            if not byte then
                return tokens.TOKEN_STRING, pos
            end
            
            if byte == character then
                if even then
                    return tokens.TOKEN_STRING, pos + 1
                end
            end
            if byte == bytes.BYTE_BACKSLASH then
                even = not even
            else
                even = true
            end
            
            pos = pos + 1
        end
    end
    
    -- INPUT
    -- 1: text: text to search in
    -- 2: tokenPos:  where to start searching
    -- OUTPUT
    -- 1: token type
    -- 2: position after the last character of the token
    function nextToken(text, pos)
        local byte = stringbyte(text, pos)
        if not byte then
            return nil
        end
        
        if linebreakCharacters[byte] then
            return tokens.TOKEN_LINEBREAK, pos + 1
        end
        
        if whitespaceCharacters[byte] then
            while true do
                pos = pos + 1
                byte = stringbyte(text, pos)
                if not byte or not whitespaceCharacters[byte] then
                    return tokens.TOKEN_WHITESPACE, pos
                end
            end
        end
        
        local token = specialCharacters[byte]
        if token then
            if token ~= -1 then
                return token, pos + 1
            end
            
            if byte == bytes.BYTE_MINUS then
                byte = stringbyte(text, pos + 1)
                if byte == bytes.BYTE_MINUS then
                    return nextComment(text, pos + 2)
                end
                return tokens.TOKEN_MINUS, pos + 1
            end
            
            if byte == bytes.BYTE_SINGLE_QUOTE then
                return nextString(text, pos + 1, bytes.BYTE_SINGLE_QUOTE)
            end
            
            if byte == bytes.BYTE_DOUBLE_QUOTE then
                return nextString(text, pos + 1, bytes.BYTE_DOUBLE_QUOTE)
            end
            
            if byte == bytes.BYTE_LEFTBRACKET then
                local isBracketString, nextPos, equalsCount = isBracketStringNext(text, pos)
                if isBracketString then
                    return nextBracketString(text, nextPos, equalsCount)
                else
                    return tokens.TOKEN_LEFTBRACKET, pos + 1
                end
            end
            
            if byte == bytes.BYTE_EQUALS then
                byte = stringbyte(text, pos + 1)
                if not byte then
                    return tokens.TOKEN_ASSIGNMENT, pos + 1
                end
                if byte == bytes.BYTE_EQUALS then
                    return tokens.TOKEN_EQUALITY, pos + 2
                end
                return tokens.TOKEN_ASSIGNMENT, pos + 1
            end
            
            if byte == bytes.BYTE_PERIOD then
                byte = stringbyte(text, pos + 1)
                if not byte then
                    return tokens.TOKEN_PERIOD, pos + 1
                end
                if byte == bytes.BYTE_PERIOD then
                    byte = stringbyte(text, pos + 2)
                    if byte == bytes.BYTE_PERIOD then
                        return tokens.TOKEN_TRIPLEPERIOD, pos + 3
                    end
                    return tokens.TOKEN_DOUBLEPERIOD, pos + 2
                elseif byte >= bytes.BYTE_0 and byte <= bytes.BYTE_9 then
                    return nextNumberFractionPart(text, pos + 2)
                end
                return tokens.TOKEN_PERIOD, pos + 1
            end
            
            if byte == bytes.BYTE_LESSTHAN then
                byte = stringbyte(text, pos + 1)
                if byte == bytes.BYTE_EQUALS then
                    return tokens.TOKEN_LTE, pos + 2
                end
                return tokens.TOKEN_LT, pos + 1
            end
            
            if byte == bytes.BYTE_GREATERTHAN then
                byte = stringbyte(text, pos + 1)
                if byte == bytes.BYTE_EQUALS then
                    return tokens.TOKEN_GTE, pos + 2
                end
                return tokens.TOKEN_GT, pos + 1
            end
            
            if byte == bytes.BYTE_TILDE then
                byte = stringbyte(text, pos + 1)
                if byte == bytes.BYTE_EQUALS then
                    return tokens.TOKEN_NOTEQUAL, pos + 2
                end
                return tokens.TOKEN_TILDE, pos + 1
            end
            
            return tokens.TOKEN_UNKNOWN, pos + 1
        elseif byte >= bytes.BYTE_0 and byte <= bytes.BYTE_9 then
            return nextNumberIntPart(text, pos + 1)
        else
            return nextIdentifier(text, pos + 1)
        end
    end
    
    -- Cool stuff begins here! (indentation and highlighting)
    
    local noIndentEffect = {0, 0}
    local indentLeft = {-1, 0}
    local indentRight = {0, 1}
    local indentBoth = {-1, 1}
    
    local keywords = {}
    lib.keywords = keywords
    keywords["and"] = noIndentEffect
    keywords["break"] = noIndentEffect
    keywords["false"] = noIndentEffect
    keywords["for"] = noIndentEffect
    keywords["if"] = noIndentEffect
    keywords["in"] = noIndentEffect
    keywords["local"] = noIndentEffect
    keywords["nil"] = noIndentEffect
    keywords["not"] = noIndentEffect
    keywords["or"] = noIndentEffect
    keywords["return"] = noIndentEffect
    keywords["true"] = noIndentEffect
    keywords["while"] = noIndentEffect
    
    keywords["until"] = indentLeft
    keywords["elseif"] = indentLeft
    keywords["end"] = indentLeft
    
    keywords["do"] = indentRight
    keywords["then"] = indentRight
    keywords["repeat"] = indentRight
    keywords["function"] = indentRight
    
    keywords["else"] = indentBoth
    
    tokenIndentation = {}
    lib.tokenIndentation = tokenIndentation
    tokenIndentation[tokens.TOKEN_LEFTPAREN] = indentRight
    tokenIndentation[tokens.TOKEN_LEFTBRACKET] = indentRight
    tokenIndentation[tokens.TOKEN_LEFTWING] = indentRight
    
    tokenIndentation[tokens.TOKEN_RIGHTPAREN] = indentLeft
    tokenIndentation[tokens.TOKEN_RIGHTBRACKET] = indentLeft
    tokenIndentation[tokens.TOKEN_RIGHTWING] = indentLeft
    
    local function fillWithTabs(n)
        return stringrep("\t", n)
    end
    
    local function fillWithSpaces(a, b)
        return stringrep(" ", a*b)
    end
    
    local defaultColorTable

    function lib.colorCodeCode(code, colorTable)
        local stopColor = colorTable and colorTable[0]
        if not stopColor then
            return {}, 0
        end
        
        local formatTable = {}
        local totalLen = 0
        
        local numLines = 0
        local prevTokenWasColored = false
        local prevTokenWidth = 0
        
        local pos = 1
        local level = 0
        
        while true do
            prevTokenWasColored = false
            prevTokenWidth = 0
            
            local tokenType, nextPos = nextToken(code, pos)
            
            if not tokenType then
                break
            end
            
            if tokenType == tokens.TOKEN_UNKNOWN then
                -- ignore color codes
                
            elseif tokenType == tokens.TOKEN_LINEBREAK or tokenType == tokens.TOKEN_WHITESPACE then
                if tokenType == tokens.TOKEN_LINEBREAK then
                    numLines = numLines + 1
                end
                local str = stringsub(code, pos, nextPos - 1)
                prevTokenWidth = nextPos - pos
                
                totalLen = totalLen + stringlen(str)
            else
                local str = stringsub(code, pos, nextPos - 1)
                
                prevTokenWidth = nextPos - pos
                
                -- Add coloring
                if keywords[str] then
                    tokenType = tokens.TOKEN_KEYWORD
                end
                
                local color
                if stopColor then
                    color = colorTable[str] or defaultColorTable[str]
                    if not color then
                        color = colorTable[tokenType] or defaultColorTable[tokenType]
                        if not color then
                            if tokenType == tokens.TOKEN_IDENTIFIER then
                                color = colorTable[tokens.TOKEN_IDENTIFIER] or defaultColorTable[tokens.TOKEN_IDENTIFIER]
                            else
                                color = colorTable[tokens.TOKEN_SPECIAL] or defaultColorTable[tokens.TOKEN_SPECIAL]
                            end
                        end
                    end
                end
                
                if color then
                    table.insert(formatTable, { pos = totalLen, val = color })
                    totalLen = totalLen + (nextPos - pos)
                    table.insert(formatTable, { pos = totalLen, val = stopColor })
                    prevTokenWasColored = true
                else
                    totalLen = totalLen + stringlen(str)
                end
            end
            
            pos = nextPos
        end
        return formatTable, numLines
    end
    
    function lib.indentCode(code, tabWidth, colorTable, caretPosition)
        local fillFunction
        if tabWidth == nil then
            tabWidth = defaultTabWidth
        end
        if tabWidth then
            fillFunction = fillWithSpaces
        else
            fillFunction = fillWithTabs
        end
        
        tableclear(workingTable)
        local tsize = 0
        local totalLen = 0
        
        tableclear(workingTable2)
        local tsize2 = 0
        local totalLen2 = 0
        
        local formatTable = {}
        
        
        local stopColor = colorTable and colorTable[0]
        
        local newCaretPosition
        local newCaretPositionFinalized = false
        local prevTokenWasColored = false
        local prevTokenWidth = 0
        
        local pos = 1
        local level = 0
        
        local hitNonWhitespace = false
        local hitIndentRight = false
        local preIndent = 0
        local postIndent = 0
        while true do
            if caretPosition and not newCaretPosition and pos >= caretPosition then
                if pos == caretPosition then
                    newCaretPosition = totalLen + totalLen2
                else
                    newCaretPosition = totalLen + totalLen2
                    local diff = pos - caretPosition
                    if diff > prevTokenWidth then
                        diff = prevTokenWidth
                    end
                    newCaretPosition = newCaretPosition - diff
                end
            end
            
            prevTokenWasColored = false
            prevTokenWidth = 0
            
            local tokenType, nextPos = nextToken(code, pos)
            
            if not tokenType or tokenType == tokens.TOKEN_LINEBREAK then
                level = level + preIndent
                if level < 0 then level = 0 end
                
                local s = fillFunction(level, tabWidth)
                
                tsize = tsize + 1
                workingTable[tsize] = s
                totalLen = totalLen + stringlen(s)
                
                if newCaretPosition and not newCaretPositionFinalized then
                    newCaretPosition = newCaretPosition + stringlen(s)
                    newCaretPositionFinalized = true
                end
                
                for k, v in next,workingTable2 do
                    if stringsub(v, 1, 2) == "|c" then
                        table.insert(formatTable, { pos = totalLen, val = stringsub(v, 3) })
                    else
                        tsize = tsize + 1
                        workingTable[tsize] = v
                        totalLen = totalLen + stringlen(v)
                    end
                end
                
                if not tokenType then
                    break
                end
                
                tsize = tsize + 1
                workingTable[tsize] = stringsub(code, pos, nextPos - 1)
                totalLen = totalLen + nextPos - pos
                
                level = level + postIndent
                if level < 0 then level = 0 end
                
                tableclear(workingTable2)
                tsize2 = 0
                totalLen2 = 0
                
                hitNonWhitespace = false
                hitIndentRight = false
                preIndent = 0
                postIndent = 0
            elseif tokenType == tokens.TOKEN_WHITESPACE then
                if hitNonWhitespace then
                    prevTokenWidth = nextPos - pos
                    
                    tsize2 = tsize2 + 1
                    local s = stringsub(code, pos, nextPos - 1)
                    workingTable2[tsize2] = s
                    totalLen2 = totalLen2 + stringlen(s)
                end
            elseif tokenType == tokens.TOKEN_UNKNOWN then
                -- skip these, though they shouldn't be encountered here anyway
            else
                hitNonWhitespace = true
                
                local str = stringsub(code, pos, nextPos - 1)
                
                prevTokenWidth = nextPos - pos
                
                -- See if this is an indent-modifier
                local indentTable
                if tokenType == tokens.TOKEN_IDENTIFIER then
                    indentTable = keywords[str]
                else
                    indentTable = tokenIndentation[tokenType]
                end
                
                if indentTable then
                    if hitIndentRight then
                        postIndent = postIndent + indentTable[1] + indentTable[2]
                    else
                        local pre = indentTable[1]
                        local post = indentTable[2]
                        if post > 0 then
                            hitIndentRight = true
                        end
                        preIndent = preIndent + pre
                        postIndent = postIndent + post
                    end
                end
                
                -- Add coloring
                if keywords[str] then
                    tokenType = tokens.TOKEN_KEYWORD
                end
                
                local color
                if stopColor then
                    color = colorTable[str] or defaultColorTable[str]
                    if not color then
                        color = colorTable[tokenType] or defaultColorTable[tokenType]
                        if not color then
                            if tokenType == tokens.TOKEN_IDENTIFIER then
                                color = colorTable[tokens.TOKEN_IDENTIFIER] or defaultColorTable[tokens.TOKEN_IDENTIFIER]
                            else
                                color = colorTable[tokens.TOKEN_SPECIAL] or defaultColorTable[tokens.TOKEN_SPECIAL]
                            end
                        end
                    end
                end
                
                if color then
                    tsize2 = tsize2 + 1
                    workingTable2[tsize2] = "|c" .. color
                    
                    tsize2 = tsize2 + 1
                    workingTable2[tsize2] = str
                    totalLen2 = totalLen2 + nextPos - pos
                    
                    tsize2 = tsize2 + 1
                    workingTable2[tsize2] = "|c" .. stopColor
                    
                    prevTokenWasColored = true
                else
                    tsize2 = tsize2 + 1
                    workingTable2[tsize2] = str
                    totalLen2 = totalLen2 + nextPos - pos
                    
                end
            end
            pos = nextPos
        end
        return table.concat(workingTable), formatTable, newCaretPosition
    end
    
    local defaultTabWidth = 4
    
    function lib.textboxReindent(textbox)
        textbox.indenting = true
        local prevPos, prevColor, v, newCaretPos, formatTable = 0, "0"
        textbox.value, formatTable, newCaret = lib.indentCode(textbox.value, textbox.tabWidth + 0, textbox.colorTable, textbox.caretpos + 0)
        local tags = iup.user { bulk = "Yes", cleanout = "Yes" }
        for i = 1, #formatTable do
            local v = formatTable[i]
            if prevPos ~= v.pos and prevColor ~= "0" then
                iup.Append(tags, iup.user { selectionpos = prevPos .. ":" .. v.pos, fgcolor = prevColor })
            end
            prevPos, prevColor = v.pos, v.val
        end
        textbox.addformattag = tags
        textbox.caretpos = newCaret
        textbox.indenting = nil
    end
    
    function lib.textboxRecolor(textbox)
        if textbox.indenting then return end
        textbox.indenting = true
        local prevPos, prevColor, oldCaret, v, formatTable = 0, "0", textbox.caretpos
        formatTable = lib.colorCodeCode(textbox.value, textbox.colorTable)
        local tags = iup.user { bulk = "Yes", cleanout = "Yes" }
        for i = 1, #formatTable do
            local v = formatTable[i]
            if prevPos ~= v.pos and prevColor ~= "0" then
                iup.Append(tags, iup.user { selectionpos = prevPos .. ":" .. v.pos, fgcolor = prevColor })
            end
            prevPos, prevColor = v.pos, v.val
        end
        textbox.addformattag = tags
        textbox.caretpos = oldCaret
        textbox.indenting = nil
    end
    
    function lib.enable(textbox, colorTable, tabWidth)
        if not colorTable then colorTable = defaultColorTable end
        if not tabWidth then tabWidth = defaultTabWidth end
        
        textbox.colorTable = colorTable
        textbox.tabWidth = tabWidth
        textbox.formatting = "Yes"
        textbox.multiline = "Yes"
        
        textbox.timer = iup.timer 
        { 
          action_cb = function(timer) 
            timer.run = "No" 
            -- TODO: optimize this to recolor only in the changed lines
            lib.textboxRecolor(textbox) 
          end, 
          time = 800
        }
 
--  AVOID: redefinition of common callbacks
--        textbox.map_cb = function(textbox) 
--          lib.textboxRecolor(textbox) 
--        end
        
        textbox.valuechanged_cb = function(textbox) 
          textbox.timer.run = "No" -- stop to start again if already running
          textbox.timer.run = "Yes" 
        end
          
--  AVOID: redefinition of common callbacks
--        textbox.k_any = function(textbox, key)
--          if key == iup.K_cF then 
--            lib.textboxReindent(textbox) 
--            return IUP_IGNORE 
--          end 
--          return IUP_CONTINUE 
--        end
    end
    
    defaultColorTable = {}
    lib.defaultColorTable = defaultColorTable
    defaultColorTable[tokens.TOKEN_SPECIAL] = "0 0 192"
    defaultColorTable[tokens.TOKEN_KEYWORD] = "0 0 255"
    defaultColorTable[tokens.TOKEN_COMMENT_SHORT] = "0 128 0"
    defaultColorTable[tokens.TOKEN_COMMENT_LONG] = "0 128 0"
    
    local stringColor = "128 128 128"
    defaultColorTable[tokens.TOKEN_STRING] = stringColor
    defaultColorTable[".."] = "0 0 128"
    
    local tableColor = "0 0 192"
    defaultColorTable["..."] = tableColor
    defaultColorTable["{"] = tableColor
    defaultColorTable["}"] = tableColor
    defaultColorTable["["] = tableColor
    defaultColorTable["]"] = tableColor
    
    local arithmeticColor = "0 0 192"
    defaultColorTable[tokens.TOKEN_NUMBER] = "255 128 0"
    defaultColorTable["+"] = arithmeticColor
    defaultColorTable["-"] = arithmeticColor
    defaultColorTable["/"] = arithmeticColor
    defaultColorTable["*"] = arithmeticColor
    
    local logicColor1 = "0 0 192"
    defaultColorTable["=="] = logicColor1
    defaultColorTable["<"] = logicColor1
    defaultColorTable["<="] = logicColor1
    defaultColorTable[">"] = logicColor1
    defaultColorTable[">="] = logicColor1
    defaultColorTable["~="] = logicColor1
    
    local logicColor2 = "0 0 255"
    defaultColorTable["and"] = logicColor2
    defaultColorTable["or"] = logicColor2
    defaultColorTable["not"] = logicColor2
    
    defaultColorTable[0] = "0"
end

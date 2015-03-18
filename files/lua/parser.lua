--- Parser generator.
-- <p>A parser is created by</p>
-- <blockquote>
-- <p><code>p = Parser {grammar}</code></p>
-- </blockquote>
-- <p>and called with</p>
-- <blockquote>
-- <p><code>result = p:parse (start_token, token_list[,
-- from])</code></p>
-- </blockquote>
-- <p>where start_token is the non-terminal at which to start parsing
-- in the grammar, token_list is a list of tokens of the form</p>
-- <blockquote>
-- <p><code>{ty = "token_type", tok = "token_text"}</code></p>
-- </blockquote>
-- <p>and from is the token in the list from which to start (the
-- default value is 1).</p>
-- <p>The output of the parser is a tree, each of whose
-- nodes is of the form:</p>
-- <blockquote>
-- <p><code>{ty = symbol, node<sub>1</sub> = tree<sub>1</sub>,
-- node<sub>2</sub> = tree<sub>2</sub>, ... [, list]}</code></p>
-- </blockquote>
-- <p>where each <code>node<sub>i</sub></code> is a symbolic name, and
-- list is the list of trees returned if the corresponding token was a
-- list token.</p>
-- <p>A grammar is a table of rules of the form</p>
-- <blockquote>
-- <p><code>non-terminal = {production<sub>1</sub>,
-- production<sub>2</sub>, ...}</code></p>
-- </blockquote>
-- <p>plus a special item</p>
-- <blockquote>
-- <p><code>lexemes = Set {"class<sub>1</sub>", "class<sub>2</sub>",
-- ...}</code></p>
-- </blockquote>
-- <p>Each production gives a form that a non-terminal may take. A
-- production has the form</p>
-- <blockquote>
-- <p><code>production = {"token<sub>1</sub>", "token<sub>2</sub>",
-- ..., [action][,abstract]}</code></p>
-- </blockquote>
-- <p>A production</p>
-- <ul>
-- <li>must not start with the non-terminal being defined (it must not
-- be left-recursive)</li>
-- <li>must not be a prefix of a later production in the same
-- non-terminal</li>
-- </ul>
-- <p>Each token may be</p>
-- <ul>
-- <li>a non-terminal, i.e. a token defined by the grammar</li>
--   <ul>
--   <li>an optional symbol is indicated by the suffix <code>_opt</code></li>
--   <li>a list is indicated by the suffix <code>_list</code>, and may be
--   followed by <code>_&le;separator-symbol&gt;</code> (default is no separator)</li>
--   </ul>
-- <li>a lexeme class</li>
-- <li>a string to match literally</li>
-- </ul>
-- <p>The parse tree for a literal string or lexeme class is the string
-- that was matched. The parse tree for a non-terminal is a table of
-- the form</p>
-- <blockquote>
-- <p><code>{ty = "non_terminal_name", tree<sub>1</sub>,
-- tree<sub>2</sub>, ...}</code></p>
-- </blockquote>
-- <p>where the <code>tree<sub>i</sub></code> are the parse trees for the
-- corresponding terminals and non-terminals.</p>
-- <p>An action is of the form</p>
-- <blockquote>
-- <p><code>action = function (tree, token, pos) ... return tree_
-- end</code></p>
-- </blockquote>
-- <p>It is passed the parse tree for the current node, the token list,
-- and the current position in the token list, and returns a new parse
-- tree.</p>
-- <p>An abstract syntax rule is of the form</p>
-- <blockquote>
-- <p><code>name = {i<sub>1</sub>, i<sub>2</sub>, ...}</code></p>
-- </blockquote>
-- <p>where <code>i<sub>1</sub></code>, <code>i<sub>2</sub></code>,
-- ... are numbers. This results in a parse tree of the form</p>
-- <blockquote>
-- <p><code>{ty = "name"; tree<sub>i<sub>1</sub></sub>,
-- tree<sub>i<sub>2</sub></sub>, ...}</code></p>
-- </blockquote>
-- <p>If a production has no abstract syntax rule, the result is the
-- parse node for the current node.</p>
-- <p>FIXME: Give lexemes as an extra argument to <code>Parser</code>?
-- <br>FIXME: Rename second argument to parse method to "tokens"?
-- <br>FIXME: Make start_token an optional argument to parse? (swap with
-- token list) and have it default to the first non-terminal?</p>
module ("parser", package.seeall)

require "object"


Parser = Object {_init = {"grammar"}}


--- Parser constructor
-- @param grammar parser grammar
-- @return parser
function Parser:_clone (grammar)
  local init = table.permute (self._init, grammar)
  -- Reformat the abstract syntax rules
  for rname, rule in pairs (init.grammar) do
    if name ~= "lexemes" then
      for pnum, prod in ipairs (rule) do
        local abstract
        for i, v in pairs (prod) do
          if type (i) == "string" and i ~= "action" then
            if abstract then
              print (prod)
              die ("more than one abstract rule for " .. rname .. "."
                   .. tostring (pnum))
            else
              if type (v) ~= "table" then
                die ("bad abstract syntax rule of type " .. type (v))
              end
              abstract = {ty = i, template = v}
              prod[i] = nil
            end
          end
        end
        if abstract then
          prod.abstract = abstract
        end
      end
    end
  end
  local object = table.merge (self, init)
  return setmetatable (object, object)
end

--- Parse a token list.
-- @param start the token at which to start
-- @param token the list of tokens
-- @param from the index of the token to start from (default: 1)
-- @return parse tree
function Parser:parse (start, token, from)

  local grammar = self.grammar -- for consistency and brevity
  local rule, symbol -- functions called before they are defined
  
  -- Try to parse an optional symbol.
  -- @param sym the symbol being tried
  -- @param from the index of the token to start from
  -- @return the resulting parse tree, or false if empty
  -- @return the index of the first unused token, or false to
  -- indicate failure
  local function optional (sym, from)
    local tree, to = symbol (sym, from)
    if to then
      return tree, to
    else
      return false, from
    end
  end

  -- Try to parse a list of symbols.
  -- @param sym the symbol being tried
  -- @param sep the list separator
  -- @param from the index of the token to start from
  -- @return the resulting parse tree, or false if empty
  -- @return the index of the first unused token, or false to
  -- indicate failure
  local function list (sym, sep, from)
    local tree, to
    tree, from = symbol (sym, from)
    local list = {tree}
    if from == false then
      return list, false
    end
    to = from
    repeat
      if sep ~= "" then
        tree, from = symbol (sep, from)
      end
      if from then
        tree, from = symbol (sym, from)
        if from then
          table.insert (list, tree)
          to = from
        end
      end
    until from == false
    return list, to
  end

  -- Try to parse a given symbol.
  -- @param sym the symbol being tried
  -- @param from the index of the token to start from
  -- @return tree the resulting parse tree, or false if empty
  -- @return the index of the first unused token, or false to
  -- indicate failure
  symbol = function (sym, from) -- declared at the top
    if string.sub (sym, -4, -1) == "_opt" then -- optional symbol
      return optional (string.sub (sym, 1, -5), from)
    elseif string.find (sym, "_list.-$") then -- list
      local _, _, subsym, sep = string.find (sym, "^(.*)_list_?(.-)$")
      return list (subsym, sep, from)
    elseif grammar[sym] then -- non-terminal
      return rule (sym, from)
    elseif token[from] and -- not end of token list
      ((grammar.lexemes[sym] and sym == token[from].ty) or
       -- lexeme
       sym == token[from].tok) -- literal terminal
    then
      return token[from].tok, from + 1 -- advance to next token
    else
      return false, false
    end
  end

  -- Try a production.
  -- @param name the name of the current rule
  -- @param prod the production (list of symbols) being tried
  -- @param from the index of the token to start from
  -- @return the parse tree (incomplete if to is false)
  -- @return the index of the first unused token, or false to
  -- indicate failure
  local function production (name, prod, from)
    local tree = {ty = name}
    local to = from
    for _, prod in ipairs (prod) do
      local sym
      sym, to = symbol (prod, to)
      if to then
        table.insert (tree, sym)
      else
        return tree, false
      end
    end
    if prod.action then
      tree = prod.action (tree, token, to)
    end
    if prod.abstract then
      local ntree = {}
      ntree.ty = prod.abstract.ty
      for i, n in prod.abstract.template do
        ntree[i] = tree[n]
      end
      tree = ntree
    end
    return tree, to
  end

  -- Parse according to a particular rule.
  -- @param name the name of the rule to try
  -- @param from the index of the token to start from
  -- @return parse tree
  -- @return the index of the first unused token, or false to
  -- indicate failure
  rule = function (name, from) -- declared at the top
    local alt = grammar[name]
    local tree, to
    for _, alt in ipairs (alt) do
      tree, to = production (name, alt, from)
      if to then
        return tree, to
      end
    end
    return tree, false
  end

  return rule (start, 1, from or 1)
end

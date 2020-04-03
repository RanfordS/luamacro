#!lua

-- read arguments
local in_name = assert (arg[1], "No input file")
local out_name = assert (arg[2], "No output file")

-- determine language
--TODO
local Lang = require "lang/c"

-- get files
local input = assert (io.open (in_name, "r")
, 'Could not open input file "'.. in_name ..'" for reading')
local output = assert (io.open (out_name, "w")
, 'Could not open output file "'.. out_name ..'" for writing')



-- read input into program
local source = {}
for line in input:lines () do
    table.insert (source, line .."\n")
end

-- find tokens
local tokens = {}
local token_length = {}
for r, line in ipairs (source) do
    for token, pattern in pairs (Lang.tokens) do
        local c = 0
        local a = 0
        while true do
            c, a = line:find (pattern, c+1)
            if not c then break end
            table.insert (tokens,
                {   row = r
                ,   col = c
                ,   aft = a
                ,   tie = token
                })
        end
    end
end

-- sort tokens
table.sort (tokens, function (a, b)
    if a.row == b.row then
        return a.col < b.col
    end
    return a.row < b.row
end)



-- match tokens into blocks and supports
local stack = {}
local blocks = {}
local supports = {}
function stack.peek (i)
    return stack[#stack-i].tie
end
local switch =
{   open = function (token)
        table.insert (stack, token)
    end
,   midd = function (token)
        assert (stack.peek (0) == "open", "found midd marker without open")
        table.insert (stack, token)
    end
,   shut = function (token)
        assert (stack.peek (0) == "midd", "found shut marker without midd")
        assert (stack.peek (1) == "open", "found shut marker without open")
        local midd = table.remove (stack)
        local open = table.remove (stack)
        table.insert (blocks,
            {   open = open
            ,   midd = midd
            ,   shut = token
            })
    end
,   supo = function (token)
        table.insert (stack, token)
    end
,   sups = function (token)
        assert (stack.peek (0) == "supo", "found sups marker without supo")
        table.insert (supports,
            {   supo = table.remove (stack)
            ,   sups = token
            })
    end
}
for _, token in ipairs (tokens) do
    switch[token.tie](token)
end
assert (#stack == 0, "unmatched markers")
stack = nil
switch = nil



-- remove supports
for _, sup in ipairs (supports) do
    local open = sup.supo
    local shut = sup.sups
    local pre = source[open.row]:sub (0,  open.col-1)
    local pro = source[shut.row]:sub (shut.aft+1, -1)
    if open.row == shut.row then
        source[open.row] = pre .. pro
    else
        source[open.row] = pre
        for i = open.row + 1, shut.row - 1 do
            source[i] = ""
        end
        source[shut.row] = pro
    end
end







-- EOF

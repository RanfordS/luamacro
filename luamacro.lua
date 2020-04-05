#!lua

-- read arguments
local in_name = assert (arg[1], "No input file")
local out_name = assert (arg[2], "No output file")

-- determine language
local ext = out_name:reverse ()
                    :match ("^(.-)%.")
                    :reverse ()
local Lang = assert (require ("lm_lang/".. ext)
, "Language definition not found for .".. ext)

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
        if #stack > 0 and stack.peek (0) == "open" then
            io.write ("\27[4mWarning:\27[0m macro inside macro script!\n")
        end
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



-- do blocks
for _, block in ipairs (blocks) do
    -- crop script
    local script = "return function (source)\n"
    if block.open.row == block.shut.row then
        -- single line special case
        local line = source[block.open.row]
        line = line:sub (block.open.aft+1, block.midd.col-1)
        script = script .. line .."\n"
    else
        -- general case
        local label = source[block.open.row]
        label = label:sub (block.open.aft+1, -1)
        label = label:gsub ("^%s*", "")
        if label ~= "" then
            io.write ("Doing macro block: ".. label)
        end
        -- extract
        for i = block.open.row+1, block.midd.row-1 do
            local line = source[i]
            if Lang.lead then
                line = line:gsub (Lang.lead, "")
            end
            script = script .. line
        end
        local midd = source[block.midd.row]
        midd = midd:sub (0, block.midd.col-1)
        script = script .. midd .."\n"
    end
    script = script .."end"

    -- crop code
    local code = ""
    if block.midd.row == block.shut.row then
        -- single line special case
        code = source[block.midd.row]
        code = code:sub (block.midd.aft+1, block.shut.col-1)
        code = code ..'\n'
    else
        -- general case
        code = source[block.midd.row]
        code = code:sub (block.midd.aft+1, -1)
        -- tidy
        if code == "\n" then code = "" end
        -- extract
        for i = block.midd.row+1, block.shut.row-1 do
            code = code .. source[i]
        end
        local shut = source[block.shut.row]
        shut = shut:sub (0, block.shut.col-1)
        code = code .. shut
    end

    -- do script
    local result = load (script)()(code)

    -- source code before and after the block
    local pre = source[block.open.row]:sub (0, block.open.col-1)
    local pro = source[block.shut.row]:sub (block.shut.aft+1, -1)
    -- trailing comment
    if pro == "\n" then
        pro = ""
    else
        pro = Lang.comm .. pro
    end
    -- write result to source
    source[block.open.row] = pre .. result .. pro
    for i = block.open.row+1, block.shut.row do
        source[i] = ""
    end

    -- macro block done
end



-- write result to file
for _, text in ipairs (source) do
    output:write (text)
end



-- Date 2020/04/05
-- Written by: Alexander J. Johnson
-- https://github.com/RanfordS

-- EOF

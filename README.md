# luamacro
A simple lua script that enables lua to be used as a macro scripting language
for C.

Easily expandable for other languages.

## Usage
Macro blocks consist of two paired regions:
1. script, which provides the lua code that performs the macro;
1. source, which provides a section of the host language to the script.

Example:
```c
/*::<macro name (optional)>
<script>
::*/
<source>
//::
```
The source region may also contain macros, which will be expanded before the
outer macro.

An additional *support* block is provided, which is intended for code that
prevents linter errors on the source file, and is removed by luamacro.
Example:
```c
/*::
<script>
::*/
//:{
#define N 2
//:}
int arr[N];
//::
```

Command: `lua luamacro.lua <source file> <dest file>`

The script determines the language based on the extension of `<dest file>`.

## Add a Language
To add support for a language, add a new file to the `lang/` folder with the
name `<ext>.lua`.
The file should return a table like this:
```lua
return {
    tokens = {
        open = "",      -- lua pattern that opens a macro block
        midd = "",      -- lua pattern that separates script and source regions
        shut = "",      -- lua pattern that closes a macro block
        supo = "",      -- lua pattern that opens a support block
        sups = "",      -- lua pattern that closes a support block
    },
    lead = false or "", -- lua pattern that preceeds all script lines
                        -- intended for languages without block comments
    comm = "",          -- single line comment string
}
```

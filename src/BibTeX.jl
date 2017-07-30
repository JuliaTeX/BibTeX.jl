module BibTeX

struct Parser
    tokens::Vector{String}
    substitutions::Dict{String, String}
    records::Dict{String, Dict{String, String}}
    line::Ref{Int}
end

Parser(text) = begin
    without_comments = replace(text, r"%.*\n", "\n")
    tokens = matchall(r"[^\s\n\"#{}@,=]+|\n|\"|#|{|}|@|,|=", without_comments)
    Parser(tokens, Dict{String, String}(), Dict{String, String}(), Ref(1))
end

location(parser) = "on line $(parser.line.x)"

next_token!(parser, eol = "additional tokens") =
    if length(parser.tokens) < 1
        error("Expected $eol $(location(parser))")
    else
        result = shift!(parser.tokens)
        if result == "\n"
            parser.line.x = parser.line.x + 1
            next_token!(parser, eol)
        else
            result
        end
    end

expect(parser, result, expectation) =
    if result != expectation
        error("Expected $expectation $(location(parser))")
    end

expect!(parser, expectation) = expect(parser, next_token!(parser, expectation), expectation)

value!(parser, values = String[]) = begin
    token = next_token!(parser)
    if token == "\""
        token = next_token!(parser, "\"")
        while token != "\""
            push!(values, token)
            token = next_token!(parser, "\"")
        end
    elseif token == "{"
        bracket_counter = 1
        while bracket_counter > 0
            token = next_token!(parser, "}")
            if token == "{"
                bracket_counter += 1
            elseif token == "}"
                bracket_counter -= 1
            else
                push!(values, token)
            end
        end
    else
        push!(values, getkey(parser.substitutions, token, token) )
    end
    token = next_token!(parser, ", or }")
    if token == "#"
        value!(parser, values)
    else
        token, join(values, " ")
    end
end

field!(parser, dict) = begin
    token = ","
    while token == ","
        token = next_token!(parser, "a new entry or }")
        if token != "}"
            key = token
            expect!(parser, "=")
            token, dict[key] = value!(parser)
        end
    end
    expect(parser, token, "}")
end

export parse_bibtex
"""
    parse_bibtex(text)

This is a simple, input parser for BibTex. I had trouble finding a standard
specification, but I've included several features of real BibTex.

```jldoctest
julia> using BibTeX

julia> result = parse_bibtex(""\"
            @comment blah blah
            @string{short = long}
            @a{b,
              c = {c {c}}, % blah blah
              d = "d d",
              e = f # short
            }
            ""\");

julia> result["b"]["type"]
"a"

julia> result["b"]["c"]
"c c"

julia> result["b"]["d"]
"d d"

julia> result["b"]["e"]
"f short"

julia> parse_bibtex("@book")
ERROR: Expected { on line 1
[...]

julia> parse_bibtex("@book@")
ERROR: Expected { on line 1
[...]
```
"""
parse_bibtex(text) = begin
    parser = Parser(text)
    while !isempty(parser.tokens)
        token = shift!(parser.tokens)
        if token == "@"
            record_type = next_token!(parser)
            if !(record_type in ["comment", "preamble"])
                expect!(parser, "{")
                if record_type == "string"
                    field!(parser, parser.substitutions)
                else
                    id = next_token!(parser)
                    dict = Dict("type" => record_type)
                    expect!(parser, ",")
                    field!(parser, dict)
                    parser.records[id] = dict
                end
            end
        end
    end
    parser.records
end

end

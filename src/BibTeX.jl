module BibTeX

struct Parser{T}
    tokens::T
    substitutions::Dict{String, String}
    records::Dict{String, Dict{String, String}}
    line::Ref{Int}
end

Base.eltype(p::Parser) = eltype(p.tokens)
Base.one(p::Parser) = eltype(p)("")

Parser(tokens::T, substitutions, records, line) where T =
    Parser{T}(tokens, substitutions, records, line)

parse_text(text) = begin
    tokens = matchall(r"[^\s\n\"#{}@,=]+|\n|\"|#|{|}|@|,|=", text)
    Parser(tokens, Dict{String, String}(), Dict{String, String}(), Ref(1))
end

location(parser) = "on line $(parser.line.x)"

next_token_default!(parser) =
    if isempty(parser.tokens)
        one(parser)
    else
        result = shift!(parser.tokens)
        if result == "\n"
            parser.line.x = parser.line.x + 1
            next_token_default!(parser)
        else
            result
        end
    end

next_token!(parser, eol = "additional tokens") = begin
    result = next_token_default!(parser)
    if result == ""
        error("Expected $eol $(location(parser))")
    else
        result
    end
end

expect(parser, result, expectation) =
    if result != expectation
        error("Expected $expectation $(location(parser))")
    end

expect!(parser, expectation) = expect(parser, next_token!(parser, expectation), expectation)

token_and_counter!(parser, bracket_counter = 1) = begin
    token = next_token!(parser, "}")
    if token == "{"
        bracket_counter += 1
    elseif token == "}"
        bracket_counter -= 1
    end
    token, bracket_counter
end

value!(parser, values = eltype(parser)[]) = begin
    token = next_token!(parser)
    if token == "\""
        token = next_token!(parser, "\"")
        while token != "\""
            push!(values, token)
            token = next_token!(parser, "\"")
        end
    elseif token == "{"
        token, counter = token_and_counter!(parser)
        while counter > 0
            push!(values, token)
            token, counter = token_and_counter!(parser, counter)
        end
    else
        push!(values, getkey(parser.substitutions, token, String(token) ) )
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

This is a simple input parser for BibTex. I had trouble finding a standard
specification, but I've included several features of real BibTex. Returns
a preamble (or an empty string) and a dict of dicts.

```jldoctest
julia> using BibTeX

julia> preamble, result = parse_bibtex(""\"
            @preamble{some instructions}
            @comment blah blah
            @string{short = long}
            @a{b,
              c = { {c} c},
              d = "d d",
              e = f # short
            }
            ""\");

julia> preamble
"some instructions"

julia> result["b"]["type"]
"a"

julia> result["b"]["c"]
"{ c } c"

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
    parser = parse_text(text)
    token = next_token_default!(parser)
    preamble = ""
    while token != ""
        if token == "@"
            record_type = lowercase(next_token!(parser))
            if record_type == "preamble"
                trash, preamble = value!(parser)
            elseif record_type != "comment"
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
        token = next_token_default!(parser)
    end
    preamble, parser.records
end

end

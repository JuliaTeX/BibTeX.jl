var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#BibTeX.parse_bibtex-Tuple{Any}",
    "page": "Home",
    "title": "BibTeX.parse_bibtex",
    "category": "Method",
    "text": "parse_bibtex(text)\n\nThis is a simple input parser for BibTex. I had trouble finding a standard specification, but I've included several features of real BibTex.\n\njulia> using BibTeX\n\njulia> result = parse_bibtex(\"\"\"\n            @string{short = long}\n            @a{b,\n              c = { {c} c},\n              d = \"d d\",\n              e = f # short\n            }\n            \"\"\");\n\njulia> result[\"b\"][\"type\"]\n\"a\"\n\njulia> result[\"b\"][\"c\"]\n\"{ c } c\"\n\njulia> result[\"b\"][\"d\"]\n\"d d\"\n\njulia> result[\"b\"][\"e\"]\n\"f short\"\n\njulia> parse_bibtex(\"@book\")\nERROR: Expected { on line 1\n[...]\n\njulia> parse_bibtex(\"@book@\")\nERROR: Expected { on line 1\n[...]\n\n\n\n"
},

{
    "location": "index.html#BibTeX.jl-1",
    "page": "Home",
    "title": "BibTeX.jl",
    "category": "section",
    "text": "Modules = [BibTeX]"
},

]}

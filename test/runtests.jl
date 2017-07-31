using BibTeX

import Documenter
Documenter.makedocs(
    modules = [BibTeX],
    format = :html,
    sitename = "BibTeX.jl",
    root = joinpath(dirname(dirname(@__FILE__)), "docs"),
    pages = Any["Home" => "index.md"],
    strict = true,
    linkcheck = true,
    checkdocs = :exports,
    authors = "Brandon Taylor"
)

# just test if it parses (for now)
joinpath((@__FILE__) |> dirname |> dirname, "example", "examples.bib") |> readstring |> parse_bibtex

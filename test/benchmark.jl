const file = joinpath((@__FILE__) |> dirname |> dirname, "example", "examples.bib") |> readstring

using BenchmarkTools
using BibTeX

@benchmark parse_bibtex(file)

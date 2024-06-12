using Random, Plots
include("plotting.jl")

for i = 1:10
    rng = MersenneTwister(i)
    x, f = random_probability_distribution(rng, 25, 25, -10.0, 10.0)
    α = 0.9

    @assert issorted(x)
    @assert all(f .≥ 0)
    @assert sum(f) ≈ 1

    dir = "images"

    @info "Distributions"
    plt1 = plot_distributions(x, f, α, addCVaR = false)
    savefig(plt1, joinpath(dir, "distributions_$(i).pdf"))

    plt1 = plot_distributions(x, f, α)
    savefig(plt1, joinpath(dir, "distributions_CVaR_$(i).pdf"))
end
# @info "VaR"
# plt2 = plot_VaR(x, f, α)

# @info "CVaR"
# plt3 = plot_CVaR(x, f)

# plt4 = plot(plt2, plt3, layout=(1, 2), legend=false, size=(720, 480))
# savefig(plt4, joinpath(dir, "conditional-value-at-risk.pdf"))

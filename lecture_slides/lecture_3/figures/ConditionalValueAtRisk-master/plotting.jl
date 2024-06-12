using Random, Plots
include("conditional-value-at-risk.jl")

function scale(x::Float64, low::Float64, high::Float64)
    return x * (high - low) + low
end

function random_probability_distribution(rng::AbstractRNG, n_neg::Int, n_pos::Int, low::Real, high::Real)
    low < high || throw(DomainError(""))
    x_neg = rand(rng, n_neg)
    x_neg = scale.(x_neg, low, 0.0)
    x_pos = rand(rng, n_pos)
    x_pos = scale.(x_pos, 0.0, high)
    x = [x_neg; x_pos]
    f = rand(rng, n_neg + n_pos)
    f = f / sum(f)
    i = sortperm(x)
    return x[i], f[i]
end

function hair(plt, x, y)
    plot!(plt, [x, x], [0, y], linewidth=1, color=:grey, alpha=0.5, label=false)
end

function plot_distribution(x, f, x_α; plt=plot())
    for (x2, f2) in zip(x, f)
        hair(plt, x2, f2)
    end
    tail = x .≥ x_α
    head = x .< x_α
    plot!(plt, ylims = (0, 1.15 * maximum(f)))
    
    if sum(tail) > 0
        plot!(plt, x[tail], f[tail], linealpha=0,
        linewidth=0, markershape=:circle,
        markercolor=:darkred, label="Tail")
    end
        plot!(plt, x[head], f[head], linealpha=0, 
        markercolor=:1, linewidth=0, markershape=:circle,
        label="")
    return plt
end

function plot_distributions(x, f, α; addCVaR=true)
    mean = sum(x.*f)
    ϵ = 0.1

    if addCVaR
        VaR = value_at_risk(x, f, α)
        CVaR = conditional_value_at_risk(x, f, α)
    end

    # Probability distribution
    plt1 = plot(
        title="Probability distribution",
        xlabel="z", ylabel="p(Z=z)",
        legend=false
    )
    if addCVaR
        plot_distribution(x, f, VaR; plt=plt1)
    else
        plot_distribution(x, f, maximum(x)+ϵ; plt=plt1)
    end 
    #Plot mean   
    plot!(plt1, [mean], [0],
        linewidth=0, markershape=:diamond,
        markersize=6, markercolor=:1,
        label="Expected value")
    if addCVaR
        plot!(plt1, [VaR], [0],
        linewidth=0, markershape=:diamond,
        markersize=6, markercolor=:2,
        label="VaR")
        plot!(plt1, [CVaR], [0],
        linewidth=0, markershape=:diamond,
        markersize=6, markercolor=:3,
        label="CVaR")
    end    

    # Cumulative probability distribution
    plt2 = plot(
        title="Cumulative distribution",
        xlabel="z", ylabel="p(Z=z)",
        legend=false
    )
    if addCVaR
        plot_distribution(x, cumsum(f), VaR; plt=plt2)
    else
        plot_distribution(x, cumsum(f), maximum(x)+ϵ; plt=plt2)
    end
    #Plot mean    
    plot!(plt2, [mean], [0],
        linewidth=0, markershape=:diamond,
        markersize=6, markercolor=:1,
        label="Expected value")
    if addCVaR    
        # plot!(plt2, x, [α for _ in x],
        #     linewidth=2, label="α",
        #     linecolor=:2)
        plot!(plt2, [VaR], [0],
            linewidth=0, markershape=:diamond,
         markersize=6, markercolor=:2,
         label="VaR")
        plot!(plt2, [CVaR], [0],
            linewidth=0, markershape=:diamond,
            markersize=6, markercolor=:3,
            label="CVaR")
    end        
    # Stacked plots
    plt = plot(plt1, plt2,
        layout=(2, 1), legend=:topleft, size=(720, 720))
end

function plot_VaR(x, f, α; plt=plot(size=(720, 480), legend=false, title="Value-at-Risk"))
    # Cumulative distribution
    F2 = cumsum(f)
    F1 = [0; F2[1:end-1]]

    plt = plot!(plt, xlabel="p")

    for i in LinearIndices(x)
        # Integral from zero to probability level α
        if F2[i] <= α
            plot!(plt, [F1[i], F2[i]], [x[i], x[i]], color=false, fill=(0, :2), fillalpha=0.9)
        end
        if F1[i] <= α <= F2[i]
            plot!(plt, [F1[i], α], [x[i], x[i]], color=false, fill=(0, :2), fillalpha=0.9)
            plot!(plt, [α, F2[i]], [x[i], x[i]], color=false, fill=(0, :1), fillalpha=0.5)
        end
        # Value-at-risk
        plot!(plt, [F1[i], F2[i]], [x[i], x[i]], color=:black)
    end

    # Inverse of cumlative distribution function
    plot!(plt, F2, x, linewidth=0, markershape=:circle, markercolor=:black, markersize=3)
    plot!(plt, F1, x, linewidth=0, markershape=:circle, markercolor=:white, markersize=3)

    # Probability level α
    plot!(plt, [α], [0], marker=:circle, color=:2)

    return plt
end

function plot_CVaR(x, f; plt=plot(size=(720, 480), legend=false, title="Conditional Value-at-Risk"))
    αs = sort([0:0.01:1; f])
    plot!(plt, xlabel="α")
    plot!(plt, [0, 1], repeat([minimum(x)], 2), linewidth=2, linestyle=:dash, alpha=0.5)
    plot!(plt, [0, 1], repeat([sum(x .* f)], 2), linewidth=2, linestyle=:dash, alpha=0.5)
    plot!(plt, αs, [conditional_value_at_risk(x, f, α) for α in αs], linewidth=2)
    return plt
end

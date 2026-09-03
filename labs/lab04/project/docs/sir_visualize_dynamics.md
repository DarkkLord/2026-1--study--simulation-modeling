```@meta
EditURL = "../scripts/sir_visualize_dynamics.jl"
```

````@example sir_visualize_dynamics
using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots, CSV

include(srcdir("sir_model.jl"))
````

Загружаем результаты сканирования

````@example sir_visualize_dynamics
df = CSV.read(datadir("beta_scan_all.csv"), DataFrame)
````

Создаём составной график

````@example sir_visualize_dynamics
p1 = plot(df.beta, df.peak, label = "Пик", xlabel = "β", ylabel = "Доля инфицированных")
plot!(p1, df.beta, df.final_inf, label = "Конечная")

p2 = plot(df.beta, df.deaths, xlabel = "β", ylabel = "Число умерших")

p3 = plot(df.beta, df.final_rec, xlabel = "β", ylabel = "Доля выздоровевших")

plot(p1, p2, p3, layout = (3, 1), size = (800, 900))
savefig(plotsdir("comprehensive_analysis.png"))
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*


using DrWatson
@quickactivate "project"

using DataFrames
using CSV
using Plots
using Statistics

include(srcdir("DES.jl"))

# Parameters
params = Dict(
    :num_customers => 10,
    :num_servers => 2,
    :mu => 1.0 / 2,
    :lam => 0.9,
    :seed => 123,
)

# Run simulation
df = DES.run_simulation(
    num_customers = params[:num_customers],
    num_servers = params[:num_servers],
    mu = params[:mu],
    lam = params[:lam],
    seed = params[:seed],
)

println("\nSimulation results:")
println("-------------------")
println("Customers: ", nrow(df))
println("Average waiting time: ", mean(df.waiting_time))
println("Average service time: ", mean(df.service_time))
println("Average system time: ", mean(df.system_time))
println("Maximum waiting time: ", maximum(df.waiting_time))


# Save data
mkpath(datadir("results"))

CSV.write(
    datadir("results", "customers.csv"),
    df,
)


# =========================
# Plot 1 — waiting time
# =========================

p1 = bar(
    df.id,
    df.waiting_time,
    xlabel = "Customer",
    ylabel = "Waiting time",
    title = "Customer waiting time",
    legend = false,
)

savefig(
    p1,
    plotsdir("waiting_time.png"),
)


# =========================
# Plot 2 — service time
# =========================

p2 = bar(
    df.id,
    df.service_time,
    xlabel = "Customer",
    ylabel = "Service time",
    title = "Customer service time",
    legend = false,
)

savefig(
    p2,
    plotsdir("service_time.png"),
)


# =========================
# Plot 3 — time in system
# =========================

p3 = bar(
    df.id,
    df.system_time,
    xlabel = "Customer",
    ylabel = "Time",
    title = "Customer time in system",
    legend = false,
)

savefig(
    p3,
    plotsdir("system_time.png"),
)


# =========================
# Plot 4 — arrival/service
# =========================

p4 = plot(
    df.id,
    df.arrival,
    marker = :circle,
    label = "Arrival",
    xlabel = "Customer",
    ylabel = "Time",
    title = "Arrival and service start",
)

plot!(
    p4,
    df.id,
    df.service_start,
    marker = :square,
    label = "Service start",
)

savefig(
    p4,
    plotsdir("arrival_service_start.png"),
)

println("\nResults saved to:")
println(datadir("results"))

println("\nPlots saved to:")
println(plotsdir())

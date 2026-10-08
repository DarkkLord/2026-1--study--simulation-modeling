module DES

using StableRNGs
using Distributions
using ConcurrentSim
using ResumableFunctions
using DataFrames

export run_simulation


@resumable function customer(
    env::Environment,
    server::Resource,
    id::Int,
    arrival_time::Float64,
    service_dist::Distribution,
    rng,
    records,
)
    @yield timeout(env, arrival_time)

    actual_arrival = now(env)

    println("Customer $id arrived: $actual_arrival")

    @yield request(server)

    service_start = now(env)

    println("Customer $id entered service: $service_start")

    service_time = rand(rng, service_dist)

    @yield timeout(env, service_time)

    service_end = now(env)

    @yield unlock(server)

    println("Customer $id exited service: $service_end")

    push!(
        records,
        (
            id = id,
            arrival = actual_arrival,
            service_start = service_start,
            service_end = service_end,
            waiting_time = service_start - actual_arrival,
            service_time = service_time,
            system_time = service_end - actual_arrival,
        ),
    )
end


function run_simulation(;
    num_customers = 10,
    num_servers = 2,
    mu = 1.0 / 2,
    lam = 0.9,
    seed = 123,
)

    rng = StableRNG(seed)

    arrival_dist = Exponential(1 / lam)
    service_dist = Exponential(1 / mu)

    sim = Simulation()
    server = Resource(sim, num_servers)

    records = NamedTuple[]

    arrival_time = 0.0

    for id in 1:num_customers
        arrival_time += rand(rng, arrival_dist)

        @process customer(
            sim,
            server,
            id,
            arrival_time,
            service_dist,
            rng,
            records,
        )
    end

    run(sim)

    return DataFrame(records)
end

end

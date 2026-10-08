module RepairModel

using ConcurrentSim
using ResumableFunctions
using Distributions
using StableRNGs
using DataFrames

export run_simulation


# ============================================================
# Mutable simulation state
# ============================================================

mutable struct SimulationState
    failed::Int
end


# ============================================================
# Machine
# ============================================================

@resumable function machine(
    env::Environment,
    repair_facility::Resource,
    failure_dist::Distribution,
    repair_dist::Distribution,
    rng,
    state::SimulationState,
)

    while true

        # ----------------------------------------------------
        # Machine works until failure
        # ----------------------------------------------------

        failure_time = rand(rng, failure_dist)

        @yield timeout(env, failure_time)

        # Machine failed
        state.failed += 1

        # ----------------------------------------------------
        # Wait for repairman
        # ----------------------------------------------------

        @yield request(repair_facility)

        # ----------------------------------------------------
        # Repair
        # ----------------------------------------------------

        repair_time = rand(rng, repair_dist)

        @yield timeout(env, repair_time)

        # Release repairman
        @yield unlock(repair_facility)

        # Machine is working again
        state.failed -= 1
    end
end


# ============================================================
# Monitor
# ============================================================

@resumable function monitor(
    env::Environment,
    state::SimulationState,
    N::Int,
    R::Int,
    dt::Float64,
    records,
)

    while true

        t = now(env)

        # Number of failed machines
        failed = state.failed

        # Number of healthy machines
        healthy = N - failed

        # Machines waiting for repair
        queue = max(failed - R, 0)

        # Number of busy repairmen
        busy = min(failed, R)

        # Fraction of busy repairmen
        utilization = busy / R

        push!(
            records,
            (
                time = t,
                healthy = healthy,
                failed = failed,
                queue = queue,
                busy_repairers = busy,
                utilization = utilization,
            ),
        )

        @yield timeout(env, dt)
    end
end


# ============================================================
# Simulation
# ============================================================

function run_simulation(;
    N::Int = 10,
    R::Int = 3,
    lambda::Float64 = 1 / 100,
    mu::Float64 = 1.0,
    sim_time::Float64 = 10_000.0,
    dt::Float64 = 1.0,
    seed::Int = 150,
)

    # --------------------------------------------------------
    # Random number generator
    # --------------------------------------------------------

    rng = StableRNG(seed)

    # --------------------------------------------------------
    # Distributions
    #
    # Exponential(scale)
    #
    # Mean failure time = 1 / lambda
    # Mean repair time  = 1 / mu
    # --------------------------------------------------------

    failure_dist = Exponential(1 / lambda)
    repair_dist = Exponential(1 / mu)

    # --------------------------------------------------------
    # Simulation environment
    # --------------------------------------------------------

    sim = Simulation()

    # R repairmen
    repair_facility = Resource(sim, R)

    # Mutable state
    state = SimulationState(0)

    # Results
    records = NamedTuple[]

    # --------------------------------------------------------
    # Create machines
    # --------------------------------------------------------

    for _ in 1:N

        @process machine(
            sim,
            repair_facility,
            failure_dist,
            repair_dist,
            rng,
            state,
        )

    end

    # --------------------------------------------------------
    # Start monitor
    # --------------------------------------------------------

    @process monitor(
        sim,
        state,
        N,
        R,
        dt,
        records,
    )

    # --------------------------------------------------------
    # Run simulation
    # --------------------------------------------------------

    run(sim, sim_time)

    return DataFrame(records)
end


end

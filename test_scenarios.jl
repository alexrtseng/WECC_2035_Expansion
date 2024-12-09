include("expansion_model.jl")

function test_scenarios(scenarios)
    outputs_directory = joinpath(@__DIR__, "results/scenario_results")
    inputs_path = joinpath(@__DIR__, "WECC_6zone_2035")

    (generators, G) = load_input_generator(inputs_path)
    (demand, nse, sample_weight, hours_per_period, P, S, W, T, Z) = load_input_demand(inputs_path)
    variability = load_input_variability(inputs_path)
    (lines, L) = load_input_network(inputs_path);

    for scenario in scenarios
        println("Modeling Scenario: ", scenario["name"])

        # load data
        carbon_tax_values = scenario["carbon_tax_values"]
        ces_values = scenario["ces_values"]
        rps_values = scenario["rps_values"]
        itc_values = scenario["itc_values"]
        ptc_values = scenario["ptc_values"]
        cap_trade_clusters = scenario["cap_trade_clusters"]
        cap_trade_values = scenario["cap_trade_values"]

        # solve model
        (generator_results,
        storage_results,
        transmission_results,
        nse_results,
        cost_results,
        time, 
        emissions_results, 
        dual_results) = solve_cap_expansion(generators, G,
        demand, S, T, Z,
        nse,
        sample_weight, hours_per_period,
        lines, L,
        variability, Gurobi.Optimizer, rps_values, ces_values, 
        carbon_tax_values, cap_trade_clusters, cap_trade_values, 
        itc_values, ptc_values)

        # write results
        test_outpath = joinpath(outputs_directory, scenario["name"])
        write_results(generator_results,
        storage_results,
        transmission_results,
        nse_results,
        cost_results,
        time,
        emissions_results,
        dual_results,
        test_outpath)

        # run a carbon cap optimization for the scenario's given emissions
        # this allows us to analyze inefficiency and compare scenarios to true optimal
        total_emissions = sum(emissions_results[:, "Total_Emissions"])
        println("Modeling optimal C02 for Scenario: ", "$(scenario["name"])_optimal_equal_co2")

        # create policy arrays
        rps_values = [-1, -1, -1, -1, -1, -1]
        ces_values = [-1, -1, -1, -1, -1, -1]
        carbon_tax_values = [-1, -1, -1, -1, -1, -1]
        cap_trade_clusters = [[1, 2, 3, 4, 5, 6]]
        cap_trade_values = [total_emissions]
        itc_values = [0, 0, 0, 0, 0, 0]
        ptc_values = [0, 0, 0, 0, 0, 0]

        # solve model again
        (generator_results,
        storage_results,
        transmission_results,
        nse_results,
        cost_results,
        time, 
        emissions_results, 
        dual_results) = solve_cap_expansion(generators, G,
        demand, S, T, Z,
        nse,
        sample_weight, hours_per_period,
        lines, L,
        variability, Gurobi.Optimizer, rps_values, ces_values, 
        carbon_tax_values, cap_trade_clusters, cap_trade_values, 
        itc_values, ptc_values)

        # write results
        test_outpath = joinpath(outputs_directory, "$(scenario["name"])_optimal_equal_co2")
        write_results(generator_results,
        storage_results,
        transmission_results,
        nse_results,
        cost_results,
        time,
        emissions_results,
        dual_results,
        test_outpath)
    end
end
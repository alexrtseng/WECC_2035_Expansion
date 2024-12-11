# no policy emissions
z1 = 1.20692e7
z2 = 2.27673e7
z3 = 4.19586e7
z4 = 3.51458e7
z5 = 1.99765e6
z6 = 5.34976e7

# scenario dictionaries
aggressive = Dict(
    "name" => "aggressive",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [0.9, 0.9, -1, 0.5, 0.6, 0.85],
    "rps_values" => [0.6, 0.6, 0.5, 0.15, 0.5, 0.3],
    "itc_values" => [0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
    "ptc_values" => [27.5, 27.5, 27.5, 27.5, 27.5, 27.5],
    "cap_trade_clusters" => [[1, 2], [5]],
    "cap_trade_values" => [25 * 10^6, 7 * 10^6]
)

conservative = Dict(
    "name" => "conservative",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [0.6, 0.6, 0.5, 0.15, 0.5, 0.3],
    "ces_values" => [0.9, 0.9, -1, -1, 0.6, 0.8],
    "itc_values" => [0.3, 0.3, 0.0, 0.0, 0.3, 0.0],
    "ptc_values" => [27.5, 27.5, 0.0, 0.0, 27.5, 0.0],
    "cap_trade_clusters" => [[1, 2], [5]],
    "cap_trade_values" => [40 * 10^6, 11.2 * 10^6]
)

linked_cap_trade = Dict(
    "name" => "linked_cap_trade",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [0.6, 0.6, 0.5, 0.15, 0.5, 0.3],
    "ces_values" => [0.9, 0.9, -1, 0.5, 0.6, 0.85],
    "itc_values" => [0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
    "ptc_values" => [27.5, 27.5, 27.5, 27.5, 27.5, 27.5],
    "cap_trade_clusters" => [[1, 2, 5]],
    "cap_trade_values" => [32 * 10^6]
)

zones_with_no_policy = Dict(
    "name" => "zones_with_no_policy",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [0.6, 0.6, 0.5, -1, 0.5, -1],
    "ces_values" => [0.9, 0.9, -1, -1, 0.6, -1],
    "itc_values" => [0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
    "ptc_values" => [27.5, 27.5, 27.5, 27.5, 27.5, 27.5],
    "cap_trade_clusters" => [[1, 2], [5]],
    "cap_trade_values" => [25 * 10^6, 7 * 10^6]
)

aggressive_no_rps = Dict(
    "name" => "aggressive_no_rps",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [0.9, 0.9, 0.8, 0.5, 0.6, 0.85],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
    "ptc_values" => [27.5, 27.5, 27.5, 27.5, 27.5, 27.5],
    "cap_trade_clusters" => [[1, 2], [5]],
    "cap_trade_values" => [25 * 10^6, 7 * 10^6]
)

red_states_keep_incentives = Dict(
    "name" => "red_states_keep_incentives",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [0.9, 0.9, -1, 0.5, 0.6, 0.85],
    "rps_values" => [0.6, 0.6, 0.5, 0.15, 0.5, 0.3],
    "itc_values" => [0, 0, 0, 0.3, 0.3, 0],
    "ptc_values" => [0, 0, 0, 27.5, 27.5, 0],
    "cap_trade_clusters" => [[1, 2], [5]],
    "cap_trade_values" => [25 * 10^6, 7 * 10^6]
)

no_incentives = Dict(
    "name" => "no_incentives",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [0.9, 0.9, -1, 0.5, 0.6, 0.85],
    "rps_values" => [0.6, 0.6, 0.5, 0.15, 0.5, 0.3],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [[1, 2], [5]],
    "cap_trade_values" => [25 * 10^6, 7 * 10^6]
)

unified_carbon_tax = Dict(
    "name" => "unified_carbon_tax",
    "carbon_tax_values" => [100, 100, 100, 100, 100, 100],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [],
    "cap_trade_values" => []
)

unified_ces_80 = Dict(
    "name" => "unified_ces_80",
    "carbon_tax_values" => [-1 , -1, -1, -1, -1, -1],
    "ces_values" => [0.8, 0.8, 0.8, 0.8, 0.8, 0.8],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [],
    "cap_trade_values" => []
)

unified_ces_100 = Dict(
    "name" => "unified_ces_100",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [1, 1, 1, 1, 1, 1],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [],
    "cap_trade_values" => []
)

unified_rps_80 = Dict(
    "name" => "unified_rps_80",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [0.8, 0.8, 0.8, 0.8, 0.8, 0.8],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [],
    "cap_trade_values" => []
)

unified_rps_100 = Dict(
    "name" => "unified_rps_100",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [1, 1, 1, 1, 1, 1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [],
    "cap_trade_values" => []
)

linked_cap_trade_80 = Dict(
    "name" => "linked_cap_trade_80",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [[1, 2, 3, 4, 5, 6]],
    "cap_trade_values" => [(z1 + z2 + z3 + z4 + z5 + z6) * 0.8] 
)

linked_cap_trade_100 = Dict(
    "name" => "linked_cap_trade_100",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [[1, 2, 3, 4, 5, 6]],
    "cap_trade_values" => [0] 
)

unlinked_cap_trade_100 = Dict(
    "name" => "unlinked_cap_trade_100",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [[1], [2], [3], [4], [5], [6]],
    "cap_trade_values" => [0,0,0,0,0,0] 
)

unified_itc = Dict(
    "name" => "unified_itc",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [],
    "cap_trade_values" => []
)

unified_ptc = Dict(
    "name" => "unified_ptc",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [27.5, 27.5, 27.5, 27.5, 27.5, 27.5],
    "cap_trade_clusters" => [],
    "cap_trade_values" => []
)

no_policy = Dict(
    "name" => "no_policy",
    "carbon_tax_values" => [-1, -1, -1, -1, -1, -1],
    "ces_values" => [-1, -1, -1, -1, -1, -1],
    "rps_values" => [-1, -1, -1, -1, -1, -1],
    "itc_values" => [0, 0, 0, 0, 0, 0],
    "ptc_values" => [0, 0, 0, 0, 0, 0],
    "cap_trade_clusters" => [],
    "cap_trade_values" => []
)



# list of dictionaries with policies to test
# uncomment the scenarios you want to run
scenarios = [
    aggressive, 
    conservative, 
    linked_cap_trade, 
    zones_with_no_policy, 
    aggressive_no_rps, 
    red_states_keep_incentives, 
    no_incentives,
    unified_carbon_tax,
    unified_ces_80,
    unified_ces_100,
    unified_rps_80,
    unified_rps_100,
    linked_cap_trade_80,
    linked_cap_trade_100,
    unlinked_cap_trade_100,
    unified_itc,
    unified_ptc,
    no_policy
]



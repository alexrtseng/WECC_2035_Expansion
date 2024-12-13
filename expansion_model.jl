using Plots, DataFrames, CSV, JuMP

## LOAD INPUTS
function load_input_generator(inputs_path)

    # Generators (and storage) data:
    generators = DataFrame(CSV.File(joinpath(inputs_path, "Generators_data.csv")))
    # Read fuels data
    fuels = DataFrame(CSV.File(joinpath(inputs_path, "Fuels_data.csv")))

    # These inputs (and the WECC data) have been reformatted from lab1 to fit this model
    generators = select(generators, :R_ID, :Resource, :Zone, :SMALL_HYDRO, :NUCLEAR, :BIO, :GEO, :THERM, :STOR, :HYDRO, :VRE,
        :Commit, :Existing_Cap_MW, :Existing_Cap_MWh, :Cap_Size, :New_Build, :Max_Cap_MW,
        :Inv_Cost_per_MWyr, :Fixed_OM_Cost_per_MWyr, :Inv_Cost_per_MWhyr, :Fixed_OM_Cost_per_MWhyr,
        :Var_OM_Cost_per_MWh, :Start_Cost_per_MW, :Start_Fuel_MMBTU_per_MW, :Heat_Rate_MMBTU_per_MWh, :Fuel,
        :Min_Power, :Ramp_Up_Percentage, :Ramp_Dn_Percentage, :Up_Time, :Down_Time, :Hydro_Energy_to_Power_Ratio,
        :Eff_Up, :Eff_Down)
    # Set of all generators
    G = generators.R_ID

    # Calculate generator (and storage) total variable costs, start-up costs, 
    # and associated CO2 per MWh and per start
    generators.Var_Cost = zeros(Float64, size(G, 1))
    generators.CO2_Rate = zeros(Float64, size(G, 1))
    generators.Start_Cost = zeros(Float64, size(G, 1))
    generators.CO2_Per_Start = zeros(Float64, size(G, 1))
    for g in G
        # Variable cost ($/MWh) = variable O&M ($/MWh) + fuel cost ($/MMBtu) * heat rate (MMBtu/MWh)
        generators.Var_Cost[g] = generators.Var_OM_Cost_per_MWh[g] +
                                 fuels[fuels.Fuel.==generators.Fuel[g], :Cost_per_MMBtu][1] * generators.Heat_Rate_MMBTU_per_MWh[g]
        # CO2 emissions rate (tCO2/MWh) = fuel CO2 content (tCO2/MMBtu) * heat rate (MMBtu/MWh)
        generators.CO2_Rate[g] = fuels[fuels.Fuel.==generators.Fuel[g], :CO2_content_tons_per_MMBtu][1] * generators.Heat_Rate_MMBTU_per_MWh[g]
        # Start-up cost ($/start/MW) = start up O&M cost ($/start/MW) + fuel cost ($/MMBtu) * start up fuel use (MMBtu/start/MW) 
        generators.Start_Cost[g] = generators.Start_Cost_per_MW[g] +
                                   fuels[fuels.Fuel.==generators.Fuel[g], :Cost_per_MMBtu][1] * generators.Start_Fuel_MMBTU_per_MW[g]
        # Start-up CO2 emissions (tCO2/start/MW) = fuel CO2 content (tCO2/MMBtu) * start up fuel use (MMBtu/start/MW) 
        generators.CO2_Per_Start[g] = fuels[fuels.Fuel.==generators.Fuel[g], :CO2_content_tons_per_MMBtu][1] * generators.Start_Fuel_MMBTU_per_MW[g]
    end

    generators[generators.STOR.>=1, :Inv_Cost_per_MWhyr]

    generators[generators.STOR.>=1, :Inv_Cost_per_MWyr]

    generators[generators.STOR.>=1, :Inv_Cost_per_MWhyr] .= 400

    return (generators, G)
end

function load_input_demand(inputs_path)
    # Read demand input data and record parameters
    demand_inputs = DataFrame(CSV.File(joinpath(inputs_path, "Load_data.csv")))
    # Value of lost load (cost of involuntary non-served energy)
    VOLL = demand_inputs.Voll[1]
    # Set of price responsive demand (non-served energy) segments
    S = convert(Array{Int64}, collect(skipmissing(demand_inputs.Demand_Segment)))
    #NOTE:  collect(skipmising(input)) is needed here in several spots because the demand inputs are not 'square' (different column lengths)

    # Data frame for price responsive demand segments (nse)
    # NSE_Cost = opportunity cost per MWh of demand curtailment
    # NSE_Max = maximum % of demand that can be curtailed in each hour
    # Note that nse segment 1 = involuntary non-served energy (load shedding) at $9000/MWh
    # and segment 2 = one segment of voluntary price responsive demand at $600/MWh (up to 7.5% of demand)
    nse = DataFrame(Segment=S,
        NSE_Cost=VOLL .* collect(skipmissing(demand_inputs.Cost_of_Demand_Curtailment_per_MW)),
        NSE_Max=collect(skipmissing(demand_inputs.Max_Demand_Curtailment)))

    # Set of sequential hours per sub-period
    hours_per_period = convert(Int64, demand_inputs.Timesteps_per_Rep_Period[1])
    # Set of time sample sub-periods (e.g. sample days or weeks)
    P = convert(Array{Int64}, 1:demand_inputs.Rep_Periods[1])
    # Sub period cluster weights = number of periods (days/weeks) represented by each sample period
    W = convert(Array{Int64}, collect(skipmissing(demand_inputs.Sub_Weights)))
    # Set of all time steps
    T = convert(Array{Int64}, demand_inputs.Time_Index)
    # Create vector of sample weights, representing how many hours in the year
    # each hour in each sample period represents
    sample_weight = zeros(Float64, size(T, 1))
    t = 1
    for p in P
        for h in 1:hours_per_period
            sample_weight[t] = W[p] / hours_per_period
            t = t + 1
        end
    end
    # Set of zones 
    Z = convert(Array{Int64}, 1:6)

    # Load/demand time series by zone (TxZ array)
    demand = select(demand_inputs, :Load_MW_z1, :Load_MW_z2, :Load_MW_z3, :Load_MW_z4, :Load_MW_z5, :Load_MW_z6)
    # Uncomment this line to explore the data if you wish:
    # show(demand, allrows=true, allcols=true)

    return (demand, nse, sample_weight, hours_per_period, P, S, W, T, Z)
end

function load_input_variability(inputs_path)

    # Read generator capacity factors by hour (used for variable renewables)
    # There is one column here for each resource (row) in the generators DataFrame
    variability = DataFrame(CSV.File(joinpath(inputs_path, "Generators_variability.csv")))
    # Drop the first column with row indexes, as these are unecessary
    variability = variability[:, 2:ncol(variability)]

    return variability
end

function load_input_network(inputs_path="complex_expansion_data/10_days/")

    # Read network data
    network = DataFrame(CSV.File(joinpath(inputs_path, "Network.csv")))
    #Again, there is a lot of entries in here we will not use (formatted for GenX inputs), so let's select what we want

    # Network map showing lines connecting zones; this has been modified from lab1 to fit this model
    lines = select(network[1:2, :],
        :Network_Lines, :z1, :z2, :z3, :z4, :z5, :z6,
        :Line_Max_Flow_MW, :Line_Min_Flow_MW, :Line_Loss_Percentage,
        :Line_Max_Reinforcement_MW, :Line_Reinforcement_Cost_per_MWyr)
    # Add fixed O&M costs for lines = 1/20 of reinforcement cost
    lines.Line_Fixed_Cost_per_MWyr = lines.Line_Reinforcement_Cost_per_MWyr ./ 20
    # Set of all lines
    L = convert(Array{Int64}, lines.Network_Lines)

    return (lines, L)
end


function solve_cap_expansion(generators, G,
    demand, S, T, Z,
    nse,
    sample_weight, hours_per_period,
    lines, L,
    variability, solver, rps_values, ces_values, carbon_tax_values,
    cap_trade_clusters, cap_trade_values,
    itc_values, ptc_values,
    print_formulation=false
    )

    # Policy values should also be index matched. CES and RPS should be % (0.0-1.0), 
    # and Carbon Tax should be $/tCO2. For all, if the zone doesn't use that 
    # policy, use -1    
    # itc_values ashould be in order of the zones and denot % "off" (tax credit)
    # ptc_values should be in order of the zones and denote $/MWh
    # cap_trade_clusters is vector of vectors of zones in each cap market
    # values are corresponding tCO2 cap

    #SUBSETS
    # Subset of G of all thermal resources subject to unit commitment constraints
    UC = intersect(generators.R_ID[generators.Commit.==1], G)
    # Subset of G NOT subject to unit commitment constraints
    ED = intersect(generators.R_ID[.!(generators.Commit .== 1)], G)
    # Subset of G of all storage resources
    STOR = intersect(generators.R_ID[generators.STOR.>=1], G)
    # Subset of G of all variable renewable resources
    VRE = intersect(generators.R_ID[generators.VRE.==1], G)
    # Subset of all new build resources
    NEW = intersect(generators.R_ID[generators.New_Build.==1], G)
    # Subset of all existing resources
    OLD = intersect(generators.R_ID[.!(generators.New_Build .== 1)], G)
    # Subset of G of all hydro resources
    HYDRO = intersect(generators.R_ID[generators.HYDRO.==1], G)
    # Subset of G of all nuclear resources
    NUCLEAR = intersect(generators.R_ID[generators.NUCLEAR.==1], G)
    # Subset of G of all bio resources
    BIO = intersect(generators.R_ID[generators.BIO.==1], G)
    # Subset of G of all geo resources
    GEO = intersect(generators.R_ID[generators.GEO.==1], G)
    # Subset of G of all small hydro resources (seperate from hydro)
    SMALL_HYDRO = intersect(generators.R_ID[generators.SMALL_HYDRO.==1], G)
    # Subset of G of all RPS qualifying resources (Hydro and VRE)
    RPS = union(VRE, SMALL_HYDRO, BIO, GEO)
    # Subset of G of all CES qualifying resources; also used for production tax credits
    CES = union(RPS, NUCLEAR, HYDRO)
    # Subset of G of all investment tax credit qualifying resources
    ITC = union(CES, STOR)


    # CARBON POLICY SUBSETS
    # Set for each zone
    G_ZONES = Vector{Vector{Int64}}(undef, maximum(Z))
    for z in Z
        G_ZONES[z] = intersect(generators.R_ID[generators.Zone.==z], G)
    end
    # Subset of all zones under an RPS policy
    RPS_POLICY = findall(x -> x != -1, rps_values)
    # Subset of all zones under a CES policy
    CES_POLICY = findall(x -> x != -1, ces_values)
    # Subset of all zones under a CAP_TRADE policy
    CAP_TRADE_MARKETS = isempty(cap_trade_clusters) ? Int[] : 1:length(cap_trade_clusters)
    # Subset of all zones under a carbon tax policy
    CARBON_POLICY = findall(x -> x != -1, carbon_tax_values)



    Expansion_Model = Model(solver)

    # DECISION VARIABLES
    # Capacity decision variables
    @variables(Expansion_Model, begin
        vCAP[g in G] >= 0     # power capacity (MW)
        vRET_CAP[g in OLD] >= 0     # retirement of power capacity (MW)
        vNEW_CAP[g in NEW] >= 0     # new build power capacity (MW)

        vE_CAP[g in STOR] >= 0     # storage energy capacity (MWh)
        vRET_E_CAP[g in intersect(STOR, OLD)] >= 0     # retirement of storage energy capacity (MWh)
        vNEW_E_CAP[g in intersect(STOR, NEW)] >= 0     # new build storage energy capacity (MWh)

        vT_CAP[l in L] >= 0     # transmission capacity (MW)
        vRET_T_CAP[l in L] >= 0     # retirement of transmission capacity (MW)
        vNEW_T_CAP[l in L] >= 0     # new build transmission capacity (MW)
    end)

    # Set upper bounds on capacity for renewable resources 
    # (which are limited in each resource 'cluster')
    for g in NEW[generators[NEW, :Max_Cap_MW].>0]
        set_upper_bound(vNEW_CAP[g], generators.Max_Cap_MW[g])
    end

    # Set upper bounds on transmission capacity expansion
    for l in L
        set_upper_bound(vNEW_T_CAP[l], lines.Line_Max_Reinforcement_MW[l])
    end

    # Operational decision variables
    @variables(Expansion_Model, begin
        vGEN[T, G] >= 0  # Power generation (MW)
        vCHARGE[T, STOR] >= 0  # Power charging (MW)
        vSOC[T, STOR] >= 0  # Energy storage state of charge (MWh)
        vNSE[T, S, Z] >= 0  # Non-served energy/demand curtailment (MW)
        vFLOW[T, L]      # Transmission line flow (MW); 
        vRESERVOIR[T, HYDRO]     # Reservoir level (MWh) for hydro resources
        vFILL[T, HYDRO]     # Water inflow (MWh) for hydro resources
        # note line flow is positive if flowing
        # from source node (indicated by 1 in zone column for that line) 
        # to sink node (indicated by -1 in zone column for that line); 
        # flow is negative if flowing from sink to source.
    end)

    # CONSTRAINTS
    # By naming convention, all constraints start with c and then are TitleCase

    # (1) Supply-demand balance constraint for all time steps and zones
    @constraint(Expansion_Model, cDemandBalance[t in T, z in Z],
        sum(vGEN[t, g] for g in intersect(generators[generators.Zone.==z, :R_ID], G)) +
        sum(vNSE[t, s, z] for s in S) -
        sum(vCHARGE[t, g] for g in intersect(generators[generators.Zone.==z, :R_ID], STOR)) -
        demand[t, z] -
        sum(lines[l, Symbol(string("z", z))] * vFLOW[t, l] for l in L) == 0
    )

    # (2-6) Capacitated constraints:
    @constraints(Expansion_Model, begin
        # (2) Max power constraints for all time steps and all generators/storage
        cMaxPower[t in T, g in setdiff(G, HYDRO)], vGEN[t, g] <= variability[t, g] * vCAP[g]
        # (2b) Max power constraints for all time steps and all hydro resources
        cMaxPowerHydro[t in T, g in HYDRO], vGEN[t, g] <= vCAP[g]
        # (3a) Max charge constraints for all time steps and all storage resources
        cMaxCharge[t in T, g in STOR], vCHARGE[t, g] <= vCAP[g]
        # (3b) Max fill constraints for all time steps and all hydro resources
        cMaxFILL[t in T, g in HYDRO], vFILL[t, g] <= vCAP[g] * variability[t, g]
        # (4a) Max state of charge constraints for all time steps and all storage resources
        cMaxSOC[t in T, g in STOR], vSOC[t, g] <= vE_CAP[g]
        # (4b) Max reservoir level constraints for all time steps and all hydro resources
        cMaxReservoir[t in T, g in HYDRO], vRESERVOIR[t, g] <= vCAP[g] * generators.Hydro_Energy_to_Power_Ratio[g]
        # (5) Max non-served energy constraints for all time steps and all segments and all zones
        cMaxNSE[t in T, s in S, z in Z], vNSE[t, s, z] <= nse.NSE_Max[s] * demand[t, z]
        # (6a) Max flow constraints for all time steps and all lines
        cMaxFlow[t in T, l in L], vFLOW[t, l] <= vT_CAP[l]
        # (6b) Min flow constraints for all time steps and all lines
        cMinFlow[t in T, l in L], vFLOW[t, l] >= -vT_CAP[l]
    end)

    # (7-9) Total capacity constraints:
    @constraints(Expansion_Model, begin
        # (7a) Total capacity for existing units
        cCapOld[g in OLD], vCAP[g] == generators.Existing_Cap_MW[g] - vRET_CAP[g]
        # (7b) Total capacity for new units
        cCapNew[g in NEW], vCAP[g] == vNEW_CAP[g]

        # (8a) Total energy storage capacity for existing units
        cCapEnergyOld[g in intersect(STOR, OLD)],
        vE_CAP[g] == generators.Existing_Cap_MWh[g] - vRET_E_CAP[g]
        # (8b) Total energy storage capacity for existing units
        cCapEnergyNew[g in intersect(STOR, NEW)],
        vE_CAP[g] == vNEW_E_CAP[g]

        # (9) Total transmission capacity
        cTransCap[l in L], vT_CAP[l] == lines.Line_Max_Flow_MW[l] - vRET_T_CAP[l] + vNEW_T_CAP[l]
    end)

    # Because we are using time domain reduction via sample periods (days or weeks),
    # we must be careful with time coupling constraints at the start and end of each
    # sample period. 

    # First we record a subset of time steps that begin a sub period 
    # (these will be subject to 'wrapping' constraints that link the start/end of each period)
    # We include some additional logic for the case of 52 weeks because the full 8760 does not line up exactly
    # with 52 weeks. There is one extra day. This logic ignores the last "start".
    STARTS = convert(Array{Int64}, 1:hours_per_period:floor(maximum(T) / hours_per_period)*hours_per_period)
    # Then we record all time periods that do not begin a sub period 
    # (these will be subject to normal time couping constraints, looking back one period)
    INTERIORS = setdiff(T, STARTS)

    # (10-12) Time coupling constraints
    @constraints(Expansion_Model, begin
        # (10a) Ramp up constraints, normal
        cRampUp[t in INTERIORS, g in G],
        vGEN[t, g] - vGEN[t-1, g] <= generators.Ramp_Up_Percentage[g] * vCAP[g]
        # (10b) Ramp up constraints, sub-period wrapping
        cRampUpWrap[t in STARTS, g in G],
        vGEN[t, g] - vGEN[t+hours_per_period-1, g] <= generators.Ramp_Up_Percentage[g] * vCAP[g]

        # (11a) Ramp down, normal
        cRampDown[t in INTERIORS, g in G],
        vGEN[t-1, g] - vGEN[t, g] <= generators.Ramp_Dn_Percentage[g] * vCAP[g]
        # (11b) Ramp down, sub-period wrapping
        cRampDownWrap[t in STARTS, g in G],
        vGEN[t+hours_per_period-1, g] - vGEN[t, g] <= generators.Ramp_Dn_Percentage[g] * vCAP[g]

        # (12a) Storage state of charge, normal
        cSOC[t in INTERIORS, g in STOR],
        vSOC[t, g] == vSOC[t-1, g] + generators.Eff_Up[g] * vCHARGE[t, g] - vGEN[t, g] / generators.Eff_Down[g]
        # (12b) Storage state of charge, wrapping
        cSOCWrap[t in STARTS, g in STOR],
        vSOC[t, g] == vSOC[t+hours_per_period-1, g] + generators.Eff_Up[g] * vCHARGE[t, g] - vGEN[t, g] / generators.Eff_Down[g]
        # (12c) Reservoir level, normal
        cReservoir[t in INTERIORS, g in HYDRO],
        vRESERVOIR[t, g] == vRESERVOIR[t-1, g] + vFILL[t, g] - vGEN[t, g]
        # (12d) Reservoir level, wrapping
        cReservoirWrap[t in STARTS, g in HYDRO],
        vRESERVOIR[t, g] == vRESERVOIR[t+hours_per_period-1, g] + vFILL[t, g] - vGEN[t, g]
    end)

    # Carbon Policy constraints
    @constraints(Expansion_Model, begin
        # 13 RPS policy constraint
        cRPS[z in RPS_POLICY],
        sum(vGEN[t, r] * sample_weight[t] for t in T, r in intersect(G_ZONES[z], RPS)) >=
        (sum(vGEN[t, g] * sample_weight[t] for t in T, g in setdiff(G_ZONES[z], STOR)) * rps_values[z])

        # 14 CES policy constraint
        cCES[z in CES_POLICY],
        sum(vGEN[t, r] * sample_weight[t] for t in T, r in intersect(G_ZONES[z], CES)) >=
        (sum(vGEN[t, g] * sample_weight[t] for t in T, g in setdiff(G_ZONES[z], STOR)) * ces_values[z])

        # 15 Cap and Trade policy constraint
        cCAP_TRADE[m in CAP_TRADE_MARKETS],
        cap_trade_values[m] >= sum(generators.CO2_Rate[g] * vGEN[t, g] * sample_weight[t] for z in cap_trade_clusters[m], t in T, g in G_ZONES[z])
    end)

    # Create expressions for each sub-component of the total cost (for later retrieval)
    @expression(Expansion_Model, eFixedCostsGeneration,
        # Fixed costs for total capacity 
        sum(generators.Fixed_OM_Cost_per_MWyr[g] * vCAP[g] for g in G) +
        # Investment cost for new capacity
        sum(generators.Inv_Cost_per_MWyr[g] * vNEW_CAP[g] for g in NEW)
    )
    @expression(Expansion_Model, eFixedCostsStorage,
        # Fixed costs for total storage energy capacity 
        sum(generators.Fixed_OM_Cost_per_MWhyr[g] * vE_CAP[g] for g in STOR) +
        # Investment costs for new storage energy capacity
        sum(generators.Inv_Cost_per_MWhyr[g] * vNEW_CAP[g] for g in intersect(STOR, NEW))
    )
    @expression(Expansion_Model, eFixedCostsTransmission,
        # Investment and fixed O&M costs for transmission lines
        sum(lines.Line_Fixed_Cost_per_MWyr[l] * vT_CAP[l] +
            lines.Line_Reinforcement_Cost_per_MWyr[l] * vNEW_T_CAP[l] for l in L)
    )
    @expression(Expansion_Model, eVariableCosts,
        # Variable costs for generation, weighted by hourly sample weight
        sum(sample_weight[t] * generators.Var_Cost[g] * vGEN[t, g] for t in T, g in G)
		
    )

    @expression(Expansion_Model, eNSECosts,
        # Non-served energy costs
        sum(sample_weight[t] * nse.NSE_Cost[s] * vNSE[t, s, z] for t in T, s in S, z in Z)
    )

	@expression(Expansion_Model, eCarbonTax,
		# Carbon tax
        sum(generators.CO2_Rate[g] * vGEN[t, g] * sample_weight[t] * carbon_tax_values[z] for z in CARBON_POLICY, g in G_ZONES[z], t in T)
	)
	
	# incentives
	@expression(Expansion_Model, eITC, 
		# Investment tax credit
		sum(generators.Inv_Cost_per_MWyr[g] * vNEW_CAP[g] * itc_values[z] for z in Z, g in intersect(G_ZONES[z], ITC, NEW))
	)

	@expression(Expansion_Model, ePTC, 
		# Production tax incentives
        sum(sample_weight[t] * vGEN[t, g] * ptc_values[z] for z in Z, g in intersect(G_ZONES[z], CES), t in T)
	)

    @expression(Expansion_Model, eTotalCosts,
        eFixedCostsGeneration + eFixedCostsStorage + eFixedCostsTransmission +
        eVariableCosts + eNSECosts + eCarbonTax - eITC - ePTC
    )

    # Expression to get total in each zone
    @expression(Expansion_Model, eTotalEmissionsInZone[z in Z],
        sum(generators.CO2_Rate[g] * vGEN[t, g] * sample_weight[t] for t in T, g in G_ZONES[z])
    )

    @objective(Expansion_Model, Min,
        eTotalCosts
    )
    if print_formulation
        print(latex_formulation(Expansion_Model))
    end

    #     optimize!(Expansion_Model)
    time = @elapsed optimize!(Expansion_Model)

    # Record generation capacity and energy results
    generation = zeros(size(G, 1))
    for i in 1:size(G, 1)
        # Note that total annual generation is sumproduct of sample period weights and hourly sample period generation 
        generation[i] = sum(sample_weight .* value.(vGEN)[:, G[i]].data)
    end
    # Total annual demand is sumproduct of sample period weights and hourly sample period demands
    total_demand = sum(sum.(eachcol(sample_weight .* demand)))
    # Maximum aggregate demand is the maximum of the sum of total concurrent demand in each hour
    peak_demand = maximum(sum(eachcol(demand)))
    MWh_share = generation ./ total_demand .* 100
    cap_share = value.(vCAP).data ./ peak_demand .* 100
    generator_results = DataFrame(
        ID=G,
        Resource=generators.Resource[G],
        Zone=generators.Zone[G],
        Total_MW=value.(vCAP).data,
        Start_MW=generators.Existing_Cap_MW[G],
        Change_in_MW=value.(vCAP).data .- generators.Existing_Cap_MW[G],
        Percent_MW=cap_share,
        GWh=generation / 1000,
        Percent_GWh=MWh_share,
    )

    # Record energy storage energy capacity results (MWh)
    storage_results = DataFrame(
        ID=STOR,
        Zone=generators.Zone[STOR],
        Resource=generators.Resource[STOR],
        Total_Storage_MWh=value.(vE_CAP).data,
        Start_Storage_MWh=generators.Existing_Cap_MWh[STOR],
        Change_in_Storage_MWh=value.(vE_CAP).data .- generators.Existing_Cap_MWh[STOR],
    )


    # Record transmission capacity results
    transmission_results = DataFrame(
        Line=L,
        Total_Transfer_Capacity=value.(vT_CAP).data,
        Start_Transfer_Capacity=lines.Line_Max_Flow_MW,
        Change_in_Transfer_Capacity=value.(vT_CAP).data .- lines.Line_Max_Flow_MW,
    )


    ## Record non-served energy results by segment and zone
    num_segments = maximum(S)
    num_zones = maximum(Z)
    nse_results = DataFrame(
        Segment=zeros(num_segments * num_zones),
        Zone=zeros(num_segments * num_zones),
        NSE_Price=zeros(num_segments * num_zones),
        Max_NSE_MW=zeros(num_segments * num_zones),
        Total_NSE_MWh=zeros(num_segments * num_zones),
        NSE_Percent_of_Demand=zeros(num_segments * num_zones),
    )
    i = 1
    for s in S
        for z in Z
            nse_results.Segment[i] = s
            nse_results.Zone[i] = z
            nse_results[!, :NSE_Price] .= nse.NSE_Cost[s]
            nse_results.Max_NSE_MW[i] = maximum(value.(vNSE)[:, s, z].data)
            nse_results.Total_NSE_MWh[i] = sum(sample_weight .* value.(vNSE)[:, s, z].data)
            nse_results.NSE_Percent_of_Demand[i] = sum(sample_weight .* value.(vNSE)[:, s, z].data) / total_demand * 100
            i = i + 1
        end
    end

    # Record costs by component (in million dollars)
    # Note: because each expression evaluates to a single value, 
    # value.(JuMPObject) returns a numerical value, not a DenseAxisArray;
    # We thus do not need to use the .data extension here to extract numeric values
    cost_results = DataFrame(
        Fixed_Costs_Generation=value.(eFixedCostsGeneration) / 10^6,
        Fixed_Costs_Storage=value.(eFixedCostsStorage) / 10^6,
        Fixed_Costs_Transmission=value.(eFixedCostsTransmission) / 10^6,
        Variable_Costs=value.(eVariableCosts) / 10^6,
        NSE_Costs=value.(eNSECosts) / 10^6,
        Objective=value.(eTotalCosts) / 10^6,
        Real_System_Cost=(value.(eTotalCosts) + value.(eITC) + value.(ePTC) - value.(eCarbonTax)) / 10^6,
		Carbon_Tax=value.(eCarbonTax) / 10^6,
		ITC=value.(eITC) / 10^6,
		PTC=value.(ePTC) / 10^6,
    )

    # Duals
    dual_results = DataFrame(Zone=Z, Cap_Trade=Vector{Union{Missing, Float64}}(undef, length(Z)), RPS=Vector{Union{Missing, Float64}}(undef, length(Z)), CES=Vector{Union{Missing, Float64}}(undef, length(Z)))

    for z in Z
        dual_results.RPS[z] = z in RPS_POLICY ? dual(cRPS[z]) : missing
        dual_results.CES[z] = z in CES_POLICY ? dual(cCES[z]) : missing
        dual_results.Cap_Trade[z] = isempty(CAP_TRADE_MARKETS) || z > length(CAP_TRADE_MARKETS) ? missing : dual(cCAP_TRADE[z])
    end

    # Create a list of the total emissions in each zone
    total_emissions=Float64[]
    for z in Z
        push!(total_emissions, value.(eTotalEmissionsInZone)[z])
    end

    # Emissions results
    emissions_results = DataFrame(Zone=Z, Total_Emissions=total_emissions)

   

    return (generator_results,
        storage_results,
        transmission_results,
        nse_results,
        cost_results,
        time, 
        emissions_results, 
        dual_results)
end

function write_results(generator_results,
    storage_results,
    transmission_results,
    nse_results,
    cost_results,
    time,
    emissions_results,
    dual_results,
    outpath)

    # If output directory does not exist, create it
    if !(isdir(outpath))
        mkdir(outpath)
    end

    CSV.write(joinpath(outpath, "generator_results.csv"), generator_results)
    CSV.write(joinpath(outpath, "storage_results.csv"), storage_results)
    CSV.write(joinpath(outpath, "transmission_results.csv"), transmission_results)
    CSV.write(joinpath(outpath, "nse_results.csv"), nse_results)
    CSV.write(joinpath(outpath, "cost_results.csv"), cost_results)
    CSV.write(joinpath(outpath, "time_results.csv"), DataFrame(time=time))
    CSV.write(joinpath(outpath, "emissions_results.csv"), emissions_results)
    CSV.write(joinpath(outpath, "dual_results.csv"), dual_results)

end

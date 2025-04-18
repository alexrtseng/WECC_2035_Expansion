# The Impact of Non-uniform Carbon Policy & Incentives on Capacity Expansion Costs
*Alex Tseng*

## Explanation
The goal of this project is to test the cost and emissions impacts of non-uniform carbon policy within the same interconnection regions. 

## Overview
The model itself can be viewed in expansion_model.jl. This model follows that explained in lab1 with modification to handle the WECC 6-zone data and additional parameter inputs to create constraints and objective function motifications to represent the given carbon policies. 

The analyze_model can be read through with the markdown section headers. The first part of this ipynb tests the model, while the second part runs an iterative test which runs a model for each scenario in scenario_dicts. This iterative function is written in test_scenarios.jl and also runs an accomponying equivalient CO2 cap model for each scenario to find the true optimal cost for a given emissions level. If you run the analyze_model.ipynb all results will be produced (it took ~3 hours on a Macbook pro with 8 available CPU cores. Or, you can skip specific scenarios by commenting them out in the scenario_dicts.jl file). For specific analysis and formating of the overall results, the last two cells can also be uncommented and run.

Alternatively, all of the result outputs are available in the results folder. 

## Results
The model_test_results contains the outputs of the initial model test. The distortive_scenario_results contains the scenario results run on the distortive CES and RPS formulation. The scenario_results represents the results of the scenarios in scenarios_dict. The results_overview contains the overview results generated by re-reading the scenario_results (as seen in the final paper).

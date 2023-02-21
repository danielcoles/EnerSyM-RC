# EnerSyM-RC
This repository provides an example of the Energy System Model for Remote Communities (EnerSyM-RC).

DESCRIPTION:
Energy System Model for Remote Communities (EnerSyM-RC) optimises the mix of renewable technologies needed to fulfil a range of system performance metrics (e.g. annual energy supply-demand balancing, instantaneious power supply-demand balancing). Full details of the model can be found in Coles et al., (2023) (https://doi.org/10.1016/j.apenergy.2023.120686), which provides a case study based on the Isle of Wight energy system. 

PRE-PROCESSING:
EnerSyM-RC is a Matlab .m file. As its inputs, its requires hourly annual timeseries of electrical demand, and power generation from solar, wind and tidal stream energy. Electrical demand data can be freely obtained from sources such as Gridwatch Templar (https://www.gridwatch.templar.co.uk/). Wind and solar PV power generation data can be freely obtained from the Renewables Ninja portal (https://www.renewables.ninja/). Tidal stream power data can be obtained from resources such as Copernicus (https://www.copernicus.eu/en/use-cases/tidal-energy-assessment-tidea). The user can pre-define the short duration battery storage capacity and storage duration.

POST-PROCESSING:
EnerSyM-RC is set up to provide the following model outputs-
e_r_d_annual: Annual renewable energy used to meet demand directly.
e_b_d_annual: Annual energy discharged from the battery to meet demand. 
e_r_g_annual: Annual renewable energy surplus that is exported to a grid, or curtailed. 
e_g_d_annual: Annual renewable energy shortage.  

CITATION:
If you use EnerSyM-RC please cite the following paper:
@article{coles2023,
title = {Impacts of tidal stream power on energy system security: An Isle of Wight case study},
author = {Daniel Coles and Bevan Wray and Rob Stevens and Scott Crawford and Shona Pennock and Jon Miles},
journal = {Applied Energy},
volume = {334},
pages = {120686},
year = {2023},
issn = {0306-2619},
doi = {https://doi.org/10.1016/j.apenergy.2023.120686}
}

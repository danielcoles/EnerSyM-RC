clc
clear

%% user defined battery specification
battery_rating=1.5;                                 %power rating of the batteries (MW)
n_batteries=150;                                    %number of batteries
duration=4;                                         %storgae duration of the batteries(hours)
eff_b=0.85;                                         %round trip battery efficiency

%% load data
load('data_dem.mat'); dem=data_dem;                 %load demand data
load('data_sol.mat'); p_sol=data_sol;               %load solar pv supply data
load('data_win.mat'); p_win=data_win;               %load wind supply data
load('data_tid.mat'); p_tid=data_tid;               %load tidal stream supply data

%% normalise renewble power supply data
p_sol_norm=(p_sol*(1/max(p_sol)));                  %normalised power at inverter (i.e. excluding cable looses to grid)
p_win_norm=(p_win*(1/max(p_win)));        
p_tid_norm=(p_tid*(1/max(p_tid)));

%% capacity factors (excluding cable losses to grid)
cf_sol=(mean(p_sol_norm)/(max(p_sol_norm)));
cf_win=(mean(p_win_norm)/(max(p_win_norm)));
cf_tid=(mean(p_tid_norm)/(max(p_tid_norm)));

%% Derive installed capacity ranges
sol_cap=linspace(0,max(dem)*1.25,7);                     %solar capacity range
win_cap=linspace(0,max(dem)*1.25,7);                     %solar capacity range

count=0;                                                 %obtain tidal stream installed capacity range
for i=1:length(win_cap)           
    for j=1:length(sol_cap)   
        count=count+1;
        
        p_sol_r=p_sol_norm*sol_cap(j)*0.9;               %solar pv delivered to grid (i.e. includes 10% cable losses)
        p_win_r=p_win_norm*win_cap(i)*0.9;               %wind power delivered to grid (i.e. includes 10% cable losses)

        e_sol_win(i,j)=sum(p_sol_r)+sum(p_win_r);        %solar and wind power delivered to grid (i.e. includes 10% cable losses)
        sho_sur(i,j)=e_sol_win(i,j)-((sum(dem)));        %remaining shortage

        tid_cap(i,j)=-(sho_sur(i,j))/(8760*cf_tid*0.9);  %tidal stream capacity needed to keep total annual renewable energy production equal to annual energy demand
          
        win_cap_b(count)=win_cap(i);
        sol_cap_b(count)=sol_cap(j);
        tid_cap_b(count)=tid_cap(i,j);
    end
end

ins_cap=horzcat(sol_cap_b',win_cap_b',tid_cap_b');
ins_cap(ins_cap(:,3)<0,:)=[];                             %installed capacity scenarios

%% battery initialisation
e_flux_max=battery_rating*n_batteries;                    %maximim battery charging/discharging energy flux per timestep. hourly resolution data so on hourly time frame, power=energy       
e_b_level_max=battery_rating*duration*n_batteries;        %maximum energy level of battery (MWh)

e_b_level=zeros(length(ins_cap),length(p_sol_norm));      %initiate battery level (starts fully charged)              
e_b_level(1,:,:)=e_b_level_max;                                           

%% Initiate energy system performance matrices
e_r_d=zeros(length(p_sol_norm),1)';                       %renewable energy to demand
e_r_b=zeros(length(p_sol_norm),1)';                       %renewable energy to the battery
e_r_g=zeros(length(p_sol_norm),1)';                       %reenewable energy curtailed/exported
e_g_d=zeros(length(p_sol_norm),1)';                       %reserve energy to demand
% 

%% run enersym-rc             
for i=1:length(ins_cap) %loop through capacity scenarios

    p_sol_i=(p_sol_norm*ins_cap(i,1))*0.9;       %solar pv power time series
    e_sol(i)=sum(p_sol_i);
    p_win_i=(p_win_norm*ins_cap(i,2))*0.9;       %wind power time series
    e_win(i)=sum(p_win_i);
    p_tid_i=(p_tid_norm*ins_cap(i,3))*0.9;       %tidal power time series
    e_tid(i)=sum(p_tid_i);    
    
    p=p_sol_i+p_win_i+p_tid_i';                  %combined renewable power timeseries
    p_mean(i)=mean(p);                           
        
        for j=2:length(p);                        %loop through each timestep, starting at t=2
            p_r=p;                                %renewable power per timesetep (MW)
            e_r=p_r;                              %renewable energy per timestep (MWh)
            e_d=dem;                              %energy demand per timestep (MWh)

            %SCENARIO 1: RENEWABLE POWER > DEMAND
            if e_r(j)>e_d(j)

                % SCENARIO 1.1: BATTERY IS NOT FULL SO CAN BE CHARGED WITH SOME/ALL SURPLUS RENEWABLE POWER   
                if e_b_level(i,j-1)<e_b_level_max
                
                    e_r_d(i,j)=e_d(j);                                %energy from the renewable plant to demand
                    e_r_b(i,j)=min(e_r(j)-e_d(j),e_flux_max) ;        %energy form the renewable plant to the battery      
                          
                    e_b_d(i,j)=0;                                     %energy from the battery to the demand
                    e_b_level(i,j)=e_b_level(i,j-1)+ e_r_b(i,j);      %energy level of the battery
                    e_b_eff_loss(i,j)=0;                              %energy lost due to efficiency of the battery (only occurs when power is discharged from the battery to the demand)

                    e_g_d(i,j)=0;                                     %reserve energy to the demand
                    e_r_g(i,j)=e_r(j)-e_r_d(i,j)-e_r_b(i,j);          %energy from the renewable plant to the external grid, or curtailed                              
                    
                    % SCENARIO 1.2: BATTERY IS FULL SO CANNOT BE CHARGED WITH SURPLUS RENEWABLE ENERGY
                    else if e_b_level(i,j-1)>=e_b_level_max 
                            
                            e_r_d(i,j)=e_d(j);                                %energy from the renewable plant to demand
                            e_r_b(i,j)=0;                                     %energy from the renewable plant to the battery (no battery losses so far)

                            e_b_d(i,j)=0;                                     %energy from the battery to the demand
                            e_b_level(i,j)=e_b_level(i,j-1)+ e_r_b(i,j);      %energy level of the battery
                            e_b_eff_loss(i,j)=0;                              %energy lost due to efficiency of the battery (only occurs when power is discharged from the battery to the datacentre)

                            e_g_d(i,j)=0;                                     %energy from the grid to the demand
                            e_r_g(i,j)=e_r(j)-e_r_d(i,j)-e_r_b(i,j);          %energy from the renewable plant to the external grid, or curtailed
                        end
                end
            end

            % SCENARIO 2: RENEWABLE POWER < DEMAND
            if e_r(j)<e_d(j)

                %SCENARIO 2.1: BATTERY USED, NO RESERVE ENERGY USED
                if e_b_level(i,j-1)>(e_d(j)-e_r(j))*(1/eff_b)

                    e_r_d(i,j)=e_r(j);                                                        %energy from the renewable plant to the demand
                    e_r_b(i,j)=0;                                                             %energy form the renewable plant to the battery

                    e_b_d(i,j)=e_d(j)-e_r_d(i,j);                                             %energy from the battery to the demand (not accounting for battery efficiency loss as this is included in e_b_eff_loss and e_b_level
                    e_b_eff_loss(i,j)=(e_b_d(i,j)/eff_b)-e_b_d(i,j);                          %energy lost due to battery efficiency
                    e_b_level(i,j)=e_b_level(i,j-1)-e_b_d(i,j)-e_b_eff_loss(i,j);             %energy level of the battery

                    e_g_d(i,j)=0;                                                             %energy from the grid to the demand
                    e_r_g(i,j)=e_r(j)-e_r_d(i,j);                                             %energy from the renewable plant to the external grid, or curtailed

                end

                % SCENARIO 2.2: BATTERY &/OR RESERVE ENERGY USED
                if e_b_level(i,j-1)<(e_d(j)-e_r(j))*(1/eff_b)

                    e_r_d(i,j)=e_r(j);                                                        %energy from the renewable plant to the demand
                    e_r_b(i,j)=0;                                                             %energy form the renewable plant to the battery

                    e_b_d(i,j)=e_b_level(i,j-1)*eff_b;                                        %energy delivered from the battery to the demand
                    e_b_eff_loss(i,j)=(e_b_d(i,j)/eff_b)-e_b_d(i,j);                          %energy lost due to efficiency of the battery
                    e_b_level(i,j)=e_b_level(i,j-1)-e_b_d(i,j)-e_b_eff_loss(i,j);             %energy level of the battery

                    e_r_g(i,j)=0;                                                             %energy from the renewable plant to the external grid, or curtailed
                    e_g_d(i,j)=e_d(j)-e_r_d(i,j)-(e_b_d(i,j));                                %energy from the grid to the demand

                end
            end
        end
end

%% post-processing:
for i=1:length(ins_cap)
    e_r_d_annual(i)=sum(e_r_d(i,:))./1000;  %annual renewable energy supply direct to meet demand
    e_b_d_annual(i)=sum(e_b_d(i,:))./1000;  %annual energy from battery to meet demand
    e_r_g_annual(i)=sum(e_r_g(i,:))./1000;  %annual renewable energy surplus (exported/curtailed energy)
    e_g_d_annual(i)=sum(e_g_d(i,:))./1000;  %annual renewable energy shortage (reliance on reserve energy)
end



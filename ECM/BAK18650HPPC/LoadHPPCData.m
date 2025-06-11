function [time, current, voltage, soc, data_length, hppc_param] = LoadHPPCData(datafile, param_file)
    dir = pwd;
    data_path = fullfile(dir, 'Data', datafile);
    param_path = fullfile(dir, 'Data', param_file);

    if ~exist(data_path, 'file')
        pm_error('Data file does not exist: %s', data_path);
    end
    if ~exist(param_path, 'file')
        pm_error('Parameter file does not exist: %s', param_path);
    end

    data = load(data_path);
    param = load(param_path);

    hppc_param.max_discharge_current = param.HPPCMaxDischargeCurrent;
    hppc_param.max_charge_current = param.HPPCMaxChargeCurrent;
    hppc_param.const_current_sweep_soc = param.HPPCConstCurrentSweepSOC;
    hppc_param.tolerance = param.HPPCTolerance;
    hppc_param.cell_capacity = param.HPPCCellCapacity;
    hppc_param.cell_initial_soc = param.HPPCCellInitialSOC;

    hppc_param.data_start_idx = 300;
    hppc_param.data_end_idx = length(data.hppcData.("time (s)"));
    data_length = hppc_param.data_end_idx - hppc_param.data_start_idx + 1;

    time = data.hppcData.("time (s)")(hppc_param.data_start_idx:hppc_param.data_end_idx) - data.hppcData.("time (s)")(hppc_param.data_start_idx);
    current = data.hppcData.("current (A)")(hppc_param.data_start_idx:hppc_param.data_end_idx);
    voltage = data.hppcData.("voltage (V)")(hppc_param.data_start_idx:hppc_param.data_end_idx);

    delta = cumtrapz(time, current);
    soc = hppc_param.cell_initial_soc + delta  / (3600 * hppc_param.cell_capacity);
    soc = min(1, max(0, soc));
end
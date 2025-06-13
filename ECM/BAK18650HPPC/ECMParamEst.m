classdef ECMParamEst
    properties(SetAccess = immutable)
        % raw data
        hppc_data_time
        hppc_data_current
        hppc_data_voltage
        hppc_data_soc
        hppc_data_length

        % HPPC parameters
        max_discharge_current
        max_charge_current
        const_current_sweep_soc
        tolerance
        cell_capacity
        cell_initial_soc
    end

    methods
        function obj = ECMParamEst(hppc_data, hppc_param)
            obj.hppc_data_time = hppc_data.time;
            obj.hppc_data_current = hppc_data.current;
            obj.hppc_data_voltage = hppc_data.voltage;
            obj.hppc_data_soc = hppc_data.soc;
            obj.hppc_data_length = hppc_data.data_length;
            obj.max_discharge_current = hppc_param.max_discharge_current;
            obj.max_charge_current = hppc_param.max_charge_current;
            obj.const_current_sweep_soc = hppc_param.const_current_sweep_soc;
            obj.tolerance = hppc_param.tolerance;
            obj.cell_capacity = hppc_param.cell_capacity;
            obj.cell_initial_soc = hppc_param.cell_initial_soc;
        end
    end
end
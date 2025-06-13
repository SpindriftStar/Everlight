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

        % options for parameter estimation
        num_rc_pairs
        init_rc_param_r
        init_rc_param_tau
    end

    methods
        function obj = ECMParamEst(hppc_data, hppc_param, rc_param)
            obj.hppc_data_time = hppc_data.time;
            obj.hppc_data_current = hppc_data.current;
            obj.hppc_data_voltage = hppc_data.voltage;
            obj.hppc_data_soc = hppc_data.soc;
            obj.hppc_data_length = hppc_data.data_length;
            % data check
            if obj.CheckHPPCData([obj.hppc_data_time,...
                                  obj.hppc_data_current,...
                                  obj.hppc_data_voltage,...
                                  obj.hppc_data_soc])
                error('Invalid HPPC data');
            end
            if ~(obj.hppc_data_length > 0 && ...
                 length(obj.hppc_data_time) == obj.hppc_data_length && ...
                 length(obj.hppc_data_current) == obj.hppc_data_length && ...
                 length(obj.hppc_data_voltage) == obj.hppc_data_length && ...
                 length(obj.hppc_data_soc) == obj.hppc_data_length)
                error('HPPC data length mismatch');
            end

            obj.max_discharge_current = abc(hppc_param.max_discharge_current);
            obj.max_charge_current = abc(hppc_param.max_charge_current);
            obj.const_current_sweep_soc = abc(hppc_param.const_current_sweep_soc);
            obj.tolerance = hppc_param.tolerance;
            obj.cell_capacity = hppc_param.cell_capacity;
            obj.cell_initial_soc = hppc_param.cell_initial_soc;
            % parameter check
            if ~(obj.max_discharge_current > 0 && ...
                 obj.max_charge_current > 0 && ...
                 obj.const_current_sweep_soc > 0 && ...
                 obj.tolerance > 0 && ...
                 obj.cell_capacity > 0 && ...
                 obj.cell_initial_soc >= 0 && obj.cell_initial_soc <= 1)
                error('Invalid HPPC parameters');
            end

            obj.num_rc_pairs = rc_param.num_rc_pairs;
            obj.init_rc_param_r = rc_param.init_rc_param_r;
            obj.init_rc_param_tau = rc_param.init_rc_param_tau;
            % options check
            if ~(obj.num_rc_pairs > 0 && ...
                 length(obj.init_rc_param_r) == obj.num_rc_pairs && ...
                 length(obj.init_rc_param_tau) == obj.num_rc_pairs)
                error('Invalid RC parameter options');
            end
        end
    end

    methods(Static)
        function flag = CheckHPPCData(data)
            is_nan = any(any(isnan(data)));
            is_inf = any(any(isinf(data)));
            flag = or(is_nan, is_inf);
        end
    end
end
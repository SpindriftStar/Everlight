classdef ECMParamEst < handle
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
        max_rc_pairs
        init_rc_param_r
        init_rc_param_tau
    end

    properties(Access = public)
        % open circuit voltage
        open_circuit_voltage

        % internal resistance
        charge_resistance
        discharge_resistance

        % RC parameters
        num_rc_pairs
        rc_param_r
        rc_param_tau
    end

    properties(Access = private)
        num_discharge_pulses
        discharge_pulse_start_idx
        discharge_pulse_end_idx
        discharge_relax_start_idx
        discharge_relax_end_idx

        num_charge_pulses
        charge_pulse_start_idx
        charge_pulse_end_idx
        charge_relax_start_idx
        charge_relax_end_idx

        num_const_current_sweeps
        const_current_sweep_start_idx
        const_current_sweep_end_idx
        sweep_relax_start_idx
        sweep_relax_end_idx

        open_circuit_voltage_idx
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

            obj.max_discharge_current = abs(hppc_param.max_discharge_current);
            obj.max_charge_current = abs(hppc_param.max_charge_current);
            obj.const_current_sweep_soc = abs(hppc_param.const_current_sweep_soc);
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
            obj.ParseHPPCData();
            obj.InternalResistanceEst();
        end
    end

    methods(Access = private)
        function ParseHPPCData(obj)
            %discharge pulse
            obj.discharge_pulse_start_idx = find(abs(abs(diff(obj.hppc_data_current)) - obj.max_discharge_current) < obj.tolerance * obj.max_discharge_current & ...
                                                 diff(obj.hppc_data_current) < 0);
            obj.discharge_pulse_end_idx = find(abs(abs(diff(obj.hppc_data_current)) - obj.max_discharge_current) < obj.tolerance * obj.max_discharge_current & ...
                                               diff(obj.hppc_data_current) > 0);
            obj.num_discharge_pulses = length(obj.discharge_pulse_start_idx);
            if ~(obj.num_discharge_pulses > 0)
                error('Discharge pulse data not found');
            end
            obj.discharge_pulse_end_idx = obj.discharge_pulse_end_idx(obj.discharge_pulse_end_idx > obj.discharge_pulse_start_idx(1));
            obj.discharge_pulse_end_idx = obj.discharge_pulse_end_idx(1:obj.num_discharge_pulses);

            % charge pulse
            obj.charge_pulse_start_idx = find(abs(abs(diff(obj.hppc_data_current)) - obj.max_charge_current) < obj.tolerance * obj.max_charge_current & ...
                                              diff(obj.hppc_data_current) > 0);
            obj.charge_pulse_end_idx = find(abs(abs(diff(obj.hppc_data_current)) - obj.max_charge_current) < obj.tolerance * obj.max_charge_current & ...
                                            diff(obj.hppc_data_current) < 0);
            obj.num_charge_pulses = length(obj.charge_pulse_start_idx);
            if ~(obj.num_charge_pulses > 0)
                error('Charge pulse data not found');
            end
            obj.charge_pulse_end_idx = obj.charge_pulse_end_idx(obj.charge_pulse_end_idx > obj.charge_pulse_start_idx(1));
            obj.charge_pulse_end_idx = obj.charge_pulse_end_idx(1:obj.num_charge_pulses);

            % const current SOC sweep
            obj.const_current_sweep_start_idx = find(abs(abs(diff(obj.hppc_data_current)) - obj.const_current_sweep_soc) < obj.tolerance * obj.const_current_sweep_soc & ...
                                                     diff(obj.hppc_data_current) < 0);
            obj.const_current_sweep_end_idx = find(abs(abs(diff(obj.hppc_data_current)) - obj.const_current_sweep_soc) < obj.tolerance * obj.const_current_sweep_soc & ...
                                                   diff(obj.hppc_data_current) > 0);
            % limit const current SOC sweep between the 1st charge pulse and the last discharge pulse
            obj.const_current_sweep_start_idx = obj.const_current_sweep_start_idx(obj.const_current_sweep_start_idx > obj.charge_pulse_end_idx(1));
            obj.const_current_sweep_start_idx = obj.const_current_sweep_start_idx(obj.const_current_sweep_start_idx < obj.discharge_pulse_start_idx(end));
            obj.num_const_current_sweeps = length(obj.const_current_sweep_start_idx);
            if ~(obj.num_const_current_sweeps > 0)
                error('Constant current sweep data not found');
            end
            obj.const_current_sweep_end_idx = obj.const_current_sweep_end_idx(obj.const_current_sweep_end_idx > obj.const_current_sweep_start_idx(1));
            obj.const_current_sweep_end_idx = obj.const_current_sweep_end_idx(1:obj.num_const_current_sweeps);

            % short relaxation between discharge pulse and charge pulse
            obj.discharge_relax_start_idx = obj.discharge_pulse_end_idx + 1;
            obj.discharge_relax_end_idx = obj.charge_pulse_start_idx;

            % short relaxation between charge pulse and const current SOC sweep
            obj.charge_relax_start_idx = obj.charge_pulse_end_idx + 1;
            obj.charge_relax_end_idx = obj.const_current_sweep_start_idx;

            % long relaxation between const current SOC sweep and the next discharge pulse
            obj.sweep_relax_start_idx = obj.const_current_sweep_end_idx + 1;
            obj.sweep_relax_end_idx = obj.discharge_pulse_start_idx;

            obj.open_circuit_voltage_idx = obj.discharge_pulse_start_idx - 1;
        end

        function InternalResistanceEst(obj)
            delta_voltage_discharge_pulse = obj.hppc_data_voltage(obj.discharge_pulse_end_idx + 1) - obj.hppc_data_voltage(obj.discharge_pulse_end_idx);
            discharge_resistance = abs(delta_voltage_discharge_pulse) / obj.max_discharge_current;
            soc = obj.hppc_data_soc(obj.discharge_pulse_end_idx);
            obj.discharge_resistance = array2table([soc, discharge_resistance], ...
                                                   'VariableNames', {'SOC', 'Discharge Resistance'});

            delta_voltage_charge_pulse = obj.hppc_data_voltage(obj.charge_pulse_end_idx + 1) - obj.hppc_data_voltage(obj.charge_pulse_end_idx);
            charge_resistance = abs(delta_voltage_charge_pulse) / obj.max_charge_current;
            soc = obj.hppc_data_soc(obj.charge_pulse_end_idx);
            obj.charge_resistance = array2table([soc, charge_resistance], ...
                                                'VariableNames', {'SOC', 'Charge Resistance'});
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
function PlotData(datafile, paramfile, plot_soc, start_idx, end_idx)
    if nargin < 3 || isempty(plot_soc)
        plot_soc = false;
    end
    if plot_soc && (nargin < 2 || isempty(paramfile))
        error('paramfile must be specified when plot_soc is true');
    end
    if nargin < 4 || isempty(start_idx)
        start_idx = 1;
    end

    dir = pwd;
    data_path = fullfile(dir, 'Data', datafile);
    if ~exist(data_path, 'file')
        error('Data file does not exist: %s', data_path);
    end

    data = load(data_path);
    if nargin < 5 || isempty(end_idx)
        time = data.hppcData.('time (s)')(start_idx:end);
        current = data.hppcData.('current (A)')(start_idx:end);
        voltage = data.hppcData.('voltage (V)')(start_idx:end);
    else
        time = data.hppcData.('time (s)')(start_idx:end_idx);
        current = data.hppcData.('current (A)')(start_idx:end_idx);
        voltage = data.hppcData.('voltage (V)')(start_idx:end_idx);
    end
    plotname = datafile;

    figure('Name', plotname);
    num_row = 2;
    if plot_soc
        num_row = 3;
        param_path = fullfile(dir, 'Data', paramfile);
        if ~exist(param_path, 'file')
            error('Parameter file does not exist: %s', param_path);
        end
        param = load(param_path);
    end

    subplot(num_row,1,1);
    plot(time, voltage, 'k-');
    xlabel('Time (s)');
    ylabel('Voltage (V)');
    title('Voltage')
    axis tight

    subplot(num_row,1,2);
    plot(time, current, 'k-');
    xlabel('Time (s)');
    ylabel('Current (A)');
    title('Current')
    axis tight

    if plot_soc
        cell_initial_soc = param.HPPCCellInitialSOC;
        cell_capacity = param.HPPCCellCapacity * 3600;
        delta = cumtrapz(time, current);
        soc = cell_initial_soc + delta  / cell_capacity;
        soc = min(1, max(0, soc));

        subplot(num_row,1,3);
        plot(time, soc, 'k-');
        xlabel('Time (s)');
        ylabel('SOC');
        title('SOC')
        axis tight
    end
end
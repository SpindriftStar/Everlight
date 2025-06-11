function PlotData(datafile)
    dir = pwd;
    data_path = fullfile(dir, 'Data', datafile);

    if ~exist(data_path, 'file')
        error('Data file does not exist: %s', data_path);
    end

    data = load(data_path);
    time = data.hppcData.('time (s)');
    current = data.hppcData.('current (A)');
    voltage = data.hppcData.('voltage (V)');
    plotname = datafile;

    figure('Name', plotname);

    subplot(2,1,1);
    plot(time, voltage, 'k-');
    xlabel('Time (s)');
    ylabel('Voltage (V)');
    title('Voltage')

    subplot(2,1,2);
    plot(time, current, 'k-');
    xlabel('Time (s)');
    ylabel('Current (A)');
    title('Current')
end
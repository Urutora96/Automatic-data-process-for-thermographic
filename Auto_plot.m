clear
clc
[FileName, PathName, ~] = uigetfile('.raw', 'Select a RAW file');
TSRData = cell2mat(struct2cell(load(fullfile(PathName, 'TSRData.mat'))));
Der1stData = cell2mat(struct2cell(load(fullfile(PathName, '1stDerData.mat'))));
Der2ndData = cell2mat(struct2cell(load(fullfile(PathName, '2ndDerData.mat'))));
APTC = cell2mat(struct2cell(load(fullfile(PathName, 'APTCMap.mat'))));
[row, col, FrameNumber] = size(TSRData);
legend_str = {};
figure('name', 'APTC Map', 'NumberTitle', 'off');
imshow(APTC, [min(APTC(:)) max(APTC(:))]);
[x, y] = ginput(1);
curve = zeros(3, FrameNumber);
while(1)
    [x, y] = ginput(1);
    try
        x = round(x);
        y = round(y);
        position = strcat('(', num2str(x), ', ', num2str(y), ')');
        legend_str = [legend_str position];
        for i = -1:1
            for j = -1:1
                Data_temp = TSRData(x + i, y + j, :);
                curve(1, :) = curve(1, :) + Data_temp(:)';
                Data_temp = Der1stData(x + i, y + j, :);
                curve(2, :) = curve(2, :) + Data_temp(:)';
                Data_temp = Der2ndData(x + i, y + j, :);
                curve(3, :) = curve(3, :) + Data_temp(:)';
            end
        end
        curve = curve/3;
        figure('name', 'TSR', 'NumberTitle', 'off');
        plot(curve(1, :));
        set(gca, 'XScale', 'log');
        set(gca, 'YScale', 'log');
        legend(legend_str);
        hold on
        
        figure('name', '1st Derivative', 'NumberTitle', 'off')
        plot(curve(2, :));
        set(gca, 'XScale', 'log');
        set(gca, 'YScale', 'log');
        legend(legend_str);
        hold on
        
        figure('name', '2nd Dervivative', 'NumberTitle', 'off')
        plot(curve(3, :));
        set(gca, 'XScale', 'log');
        set(gca, 'YScale', 'log');
        legend(legend_str);
        hold on
    catch
        if isempty(x) || isempty(y)
            break
        end
        break
    end
end
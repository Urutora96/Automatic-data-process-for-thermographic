clear
clc
while(1)
    [FileName, PathName, ~] = uigetfile('.mat', 'Select a matrix');
    if isnumeric(FileName) || isnumeric(PathName)
        break
    else
        Data=cell2mat(struct2cell(load(fullfile(PathName, FileName))));
        if length(size(Data)) == 3
            while(1)
                [row, col, FrameNumber] = size(Data);
                Dif_Cube = zeros(row, col, FrameNumber);
                APTCMap = zeros(row, col);
                Load_APTCMap = cell2mat(struct2cell(load(fullfile(PathName, 'APTCMap.mat'))));
                imshow(Load_APTCMap, [min(Load_APTCMap(:)) max(Load_APTCMap(:))]);
                colormap(jet);
                xlabel('x');
                ylabel('y');
                grid on
                set(gca, 'GridColor', 'r');
                set(gca, 'LineWidth', 1.5);
                axis on
                while(1)
                    xy1=inputdlg({'x', 'y'}, 'Select Sound Area', [1 35], {'1', '1'}, struct('WindowStyle', 'normal'));
                    xy2=inputdlg({'x', 'y'}, 'Select Sound Area', [1 35], {num2str(col), num2str(row)}, struct('WindowsStyle', 'normal'));
                    try
                        x1=str2double(xy1(1));
                        x2=str2double(xy2(1));
                        y1=str2double(xy1(2));
                        y2=str2double(xy2(2));
                    catch
                        if isempty(xy1) || isempty(xy2)
                            close all
                            return
                        else
                            h=msgbox('Input Error! Please try again!', 'Error', 'error');
                            waitfor(h)
                            continue
                        end
                    end
                    if x2>x1 && y2>y1 && x1>0 && x2>0 && y1>0 && y2>0 && x1<col && x2<col && y1<row && y2<row
                        close all
                        p=msgbox('Processing...Please Wait...', 'Processing');
                        break
                    else
                        h=msgbox('Input Error! Please try again!', 'Error', 'error');
                        waitfor(h)
                    end
                end
                sample = [];
                for i = 1:FrameNumber
                    Frame = Data(:, :, i);
                    for j = y1:y2
                        for k = x1:x2
                            sample = [sample Frame(j, k)];
                        end
                    end
                    sample_mean = mean(sample);
                    for l = 1:row
                        for m = 1:col
                            Dif_Cube(l, m, i) = abs(Frame(l, m) -sample_mean);
                        end
                    end
                    sample = [];
                end
            %% Select the peak value
                for i = 1:row
                    for j = 1:col
                        pixel = Dif_Cube(i, j, :);
                        pixel = pixel(:)';
                        peakvalue = findpeaks(pixel);
                        try
                            APTCMap(i, j) = max(peakvalue);
                        catch
                        end
                    end
                end
            %% Apply filter
                APTCMap = filter2(fspecial('average', 5), APTCMap);
                close(p);
                imshow(APTCMap, [min(APTCMap(:)) max(APTCMap(:))]);
                colormap(jet);
                selection = questdlg('Have the ideal image got?', 'Confirmation', 'Yes', 'No', 'Yes');
                if strcmp(selection, 'Yes') == 1
                    save(fullfile(PathName, 'APTCMap.mat'), 'APTCMap'); 
                    saveas(gcf, fullfile(PathName, 'APTCMap.jpg'));
                    close all
                    break
                else
                    close all
                end
            end
            %% Calculate Confidence Map
            ConfidenceMap = zeros(row, col);
            BinaryMap = zeros(row, col);
            h = msgbox('Calculating Confidence Map', 'Processing');
            sample=zeros(1, 100);
            for i=1:100
                if i<25
                    x_ran = randi(col-1, 1);
                    y_ran = randi(5-1, 1);
                    sample(i)=APTCMap(y_ran, x_ran);
                elseif i<50
                    x_ran = randi(col-1, 1);
                    y_ran = randi(5-1, 1);
                    sample(i)=APTCMap(row-y_ran, x_ran);
                elseif i<75
                    x_ran = randi(5-1, 1);
                    y_ran = randi(row-1, 1);
                    sample(i)=APTCMap(y_ran, x_ran);
                else
                    x_ran = randi(5-1, 1);
                    y_ran = randi(row-1, 1);
                    sample(i)=APTCMap(y_ran, col-x_ran);
                end
            end
            sample_mean = mean(sample);
            sample_std = std(sample);
            for i = 1:row
                for j = 1:col
                    dif = abs(APTCMap(i, j) - sample_mean)/sample_std;
                    if dif<0.674
                        ConfidenceMap(i, j) = 0;
                    elseif dif<0.842
                        ConfidenceMap(i, j) = 1;
                    elseif dif<1.036
                        ConfidenceMap(i, j) = 2;
                    elseif dif<1.282
                        ConfidenceMap(i, j) = 3;
                    elseif dif<1.645
                        ConfidenceMap(i, j) = 4;
                    elseif dif<1.96
                        ConfidenceMap(i, j) = 5;
                    elseif dif<2.236
                        ConfidenceMap(i, j) = 6;
                    elseif dif<2.576
                        ConfidenceMap(i, j) = 7;
                    elseif dif<3.09
                        ConfidenceMap(i, j) = 8;
                    elseif dif<3.291
                        ConfidenceMap(i, j) = 9;
                    else
                        ConfidenceMap(i, j) = 10;
                    end
                end
            end
            close(h);
            contourf(flipud(ConfidenceMap));
            colormap(jet(11));
            axis equal
            axis off
            h = colorbar('Ticks',[0:10],...
                    'TickLabels',{'0','50','60','70','80','90','95','98','99','99.8','99.9'});
            xlabel(h, '%')
            saveas(gcf, fullfile(PathName, 'Confidence Map.jpg'));
            BinaryMap(ConfidenceMap > 7) = 10;
            save(fullfile(PathName, 'BinaryMap.mat'));
            close all
            return
        else
            h = msgbox('Please select a 3D matrix', 'Error', 'error');
            waitfor(h)
        end
    end
end
close all
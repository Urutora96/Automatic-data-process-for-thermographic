function [result, selection]=APTC_and_Confidence(PathName)
FileName=["TSRData.mat", "1stDerData.mat", "2ndDerData.mat"];
titles=["TSR(0)", "1st Derivate(1)", "2nd Derivate(2)"];
Data_tmp=cell2mat(struct2cell(load(fullfile(PathName, FileName(1)))));
[row, col, FrameNumber] = size(Data_tmp);
APTCMap = zeros(row, col, 3);      
msg = msgbox('Calculating APTC Map...', 'Calculating');
for count=1:length(FileName)
%% Dif_Cube Calculation
    Data=cell2mat(struct2cell(load(fullfile(PathName, FileName(count)))));
    Dif_Cube=zeros(row, col, FrameNumber);
    for i=1:FrameNumber
        Frame=Data(:, :, i);
        % Sampling
        sample = [];
        for j = 20:70
            for m = 110:160
                sample = [sample Frame(j, m)];
            end
        end
        sample_mean = mean(sample);
        for l=1:row
            for m=1:col
                Dif_Cube(l, m, i) = abs(Frame(l, m)- sample_mean);
            end
        end
    end
%% Select the peak value
    for i=1:row
        for j=1:col
            pixel = Dif_Cube(i, j, :);
            pixel = pixel(:)';
            peakvalue = findpeaks(pixel);
            try
                APTCMap(i, j, count) = max(peakvalue);
            catch
            end
        end
    end
%% Apply filter
    APTCMap(:, :, count) = filter2(fspecial('average',5),APTCMap(:, :, count));
%% Plot map
    subplot(1, 3, count);
    APTC=APTCMap(:, :, count);
    imshow(APTC, [min(APTC(:)) max(APTC(:))]);
    title(titles(count));
    grid on
    colormap(jet)
    axis on
end
close(msg);
%% Select the source of Confidence Map and save it
selection = inputdlg('Select a source which reach the best quality(0, 1 or 2)', 'Select a source', 1, {'0', '1', '2'},  struct('WindowsStyle', 'normal'));
close all
msg = msgbox('Calculating Confidence Map...', 'Calculating');
ConfidenceMap = zeros(row, col);
BinaryMap = zeros(row, col);
try 
    selection = str2double(selection);
    if selection == 0 || selection ==1 || selection ==2
        APTC = APTCMap(:, :, selection+1);
        imshow(APTC, [min(APTC(:)) max(APTC(:))]);
        grid on
        colormap(jet);
        axis on
        saveas(gcf, fullfile(PathName, 'APTCMap.jpg'));
        save(fullfile(PathName, 'APTCMap.mat'), 'APTC');
        close all
        %% Sampling
        sample=zeros(1, 100);
        for i=1:100
            if i<25
                x_ran = randi(col-1, 1);
                y_ran = randi(5-1, 1);
                sample(i)=APTC(y_ran, x_ran);
            elseif i<50
                x_ran = randi(col-1, 1);
                y_ran = randi(5-1, 1);
                sample(i)=APTC(row-y_ran, x_ran);
            elseif i<75
                x_ran = randi(5-1, 1);
                y_ran = randi(row-1, 1);
                sample(i)=APTC(y_ran, x_ran);
            else
                x_ran = randi(5-1, 1);
                y_ran = randi(row-1, 1);
                sample(i)=APTC(y_ran, col-x_ran);
            end
        end
        sample_mean=mean(sample);
        sample_std=std(sample);
        
        for i=1:row
            for j=1:col
                dif = abs(APTC(i, j)-sample_mean)*1.0/sample_std;
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
        contourf(flipud(ConfidenceMap));
        colormap(jet(11));
        axis equal
        axis off
        h = colorbar('Ticks',[0:10],...
                'TickLabels',{'0','50','60','70','80','90','95','98','99','99.8','99.9'});
        xlabel(h, '%')
        saveas(gcf, fullfile(PathName, 'Confidence Map.jpg'));
        BinaryMap(ConfidenceMap > 7) = 10;
        imshow(BinaryMap);
        colormap(jet)
        axis equal
        axis off
        saveas(gcf, fullfile(PathName, 'BinaryMap.jpg'));
        save(fullfile(PathName, 'BinaryMap.mat'), 'BinaryMap');
        result = 1;
        close(msg);
        close all
    else
        result = 0;
        close(msg);
        return
    end
catch
    result = 0;
    close(msg);
    return
end
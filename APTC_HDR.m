function [result] = APTC_HDR(PathName, FileName)
%clear
%clc
%PathName = 'C:\Users\luowe\Cranfield University\Li, Gen - 小组项目研究 Private\Source Code\16holes';
%FileName = '2ndDerData.mat';
Data = cell2mat(struct2cell(load(fullfile(PathName, FileName))));
APTC = cell2mat(struct2cell(load(fullfile(PathName, 'APTCMap.mat'))));
[row, col, FrameNumber] = size(Data);
APTC_HDR = zeros(row, col);
maxvalue = max(APTC(:));
minvalue = min(APTC(:));
for i = 1:row
    for j = 1:col
        APTC_HDR(i, j) = 256/(maxvalue - minvalue) * APTC(i,j); %Convert APTC to 256 scale;
    end
end
while(1)
    imshow(APTC_HDR, [min(APTC_HDR(:)) max(APTC_HDR(:))]);
    colormap(jet);
    title('Please select the ROI');
    h = imrect;
    pos = getPosition(h);
    ROI_x1 = round(pos(1));
    ROI_x2 = round(pos(1) + pos(3));
    ROI_y1 = round(pos(2));
    ROI_y2 = round(pos(2) + pos(4));
    clear h
    clear pos
    
    title('Please select the sound area')
    h = imrect;
    pos = getPosition(h);
    ROIS_x1 = round(pos(1));
    ROIS_x2 = round(pos(1) + pos(3));
    ROIS_y1 = round(pos(2));
    ROIS_y2 = round(pos(2) + pos(4));
    clear h
    clear pos
    close all
    msg = msgbox('Applying HDR Process', 'Processing');
    %% Dif_Cube Calculation
    Dif_Cube = zeros(ROI_y2 - ROI_y1 + 1, ROI_x2 - ROI_x1 + 1, FrameNumber);
    sample = zeros(ROIS_y2 - ROIS_y1 + 1, ROIS_x2 - ROI_x1 +1);
    for i = 1:FrameNumber
    %%%%%%%%% Sampling from Sound Area %%%%%%%%
        Frame = Data(:, :, i);
        for j = ROIS_y1:ROIS_y2
            for k = ROIS_x1:ROIS_x2
                sample(j - ROIS_y1 +1, k - ROIS_x1 + 1) = Frame(j, k);
            end
        end
        sample_mean = mean(sample(:));
        for l = ROI_y1:ROI_y2
            for m = ROI_x1:ROI_x2
                Dif_Cube(l - ROI_y1 + 1, m - ROI_x1 + 1, i)=abs(Frame(l, m) - sample_mean);
            end
        end
        sample = zeros(ROIS_y2 - ROIS_y1 + 1, ROIS_x2 - ROIS_x1 +1);
    end
    %% Select the peak value
    APTCMap_2 = zeros(ROI_y2-ROI_y1+1,ROI_x2-ROI_x1+1);
    for i = 1:ROI_y2 - ROI_y1 + 1
        for j = 1:ROI_x2 - ROI_x1 + 1
            pixel = Dif_Cube(i, j, :);
            pixel = pixel(:)';
            peakvalue = findpeaks(pixel);
            try
                APTCMap_2(i, j) = max(peakvalue);
            catch
            end
        end
    end
    %% Apply filter and reconstruct the map
    APTCMap_2 = filter2(fspecial('average',3),APTCMap_2);
    APTCMap_2_HDR = zeros(ROI_y2-ROI_y1+1,ROI_x2-ROI_x1+1);
    maxvalue = max(APTCMap_2(:));
    minvalue = min(APTCMap_2(:));
    for i = 1:ROI_y2 - ROI_y1 + 1
        for j = 1:ROI_x2 - ROI_x1 + 1
            APTCMap_2_HDR(i,j)=256/(maxvalue - minvalue)*APTCMap_2(i,j); %Convert APTC to 256 scale;
            APTC_HDR(ROI_y1 + i - 1,ROI_x1 + j - 1) = APTCMap_2_HDR(i, j);
        end
    end
    imshow(APTC_HDR, [min(APTC_HDR(:)) max(APTC_HDR(:))]);
    colormap(jet);
    close(msg);
    answer = questdlg('Did you get enough ROIs?', 'Confirmation', 'Yes', 'No', 'Yes');
    if strcmp(answer, 'Yes')
        save(fullfile(PathName, 'ATPCMap.mat'), 'APTC_HDR');
        saveas(gcf, fullfile(PathName, 'APTCMap.jpg'));
        close all
        %% Calculate Confidence Map
        ConfidenceMap = zeros(row, col);
        BinaryMap = zeros(row, col);
        sample = zeros(1, 100);
        for i = 1:100
            if i<25
                x_ran = randi(col - 1, 1);
                y_ran = randi(5-1, 1);
                sample(i) = APTC_HDR(y_ran, x_ran);
            elseif i<50
                x_ran = randi(col -1, 1);
                y_ran = randi (5 - 1, 1);
                sample(i) = APTC_HDR(row - y_ran, x_ran);
            elseif i<75
                x_ran = randi(5 - 1, 1);
                y_ran = randi(row - 1, 1);
                sample(i) = APTC_HDR(y_ran, x_ran);
            else
                x_ran = randi(5 - 1, 1);
                y_ran = randi(row - 1, 1);
                sample(i) = APTC_HDR(y_ran, col - x_ran);
            end
            sample_mean = mean(sample);
            sample_std = std(sample);
        end
            
        for i = 1:row
            for j = 1:col
                dif = abs(APTC_HDR(i, j) - sample_mean)/sample_std;
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
        imshow(BinaryMap, [min(BinaryMap(:)) max(BinaryMap(:))]);
        colormap(jet(11));
        axis equal
        axis off
        save(fullfile(PathName, 'BinaryMap.mat'), 'BinaryMap');
        saveas(gcf, fullfile(PathName, 'BinaryMap.jpg'));
        result = 1;
        close all
        return
    else
        close all
    end
end
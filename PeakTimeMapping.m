function [result]=PeakTimeMapping(PathName, x1, y1)
h = msgbox('Calculating Peak Time Map...', 'Calculating');
Der2ndData=cell2mat(struct2cell(load(fullfile(PathName, '2ndDerData.mat'))));
BinaryMap = cell2mat(struct2cell(load(fullfile(PathName, 'BinaryMap.mat'))));
[row, col, ~]=size(Der2ndData);
PeakTimeMap=zeros(row, col);
PeakTimeMap_recon = zeros(303, 447);
coefficient = 0.3356*0.1;
 %% Peak Time Map Calculation 
for i=1:row
    for j=1:col
        pixel=Der2ndData(i, j, :);
        pixel=pixel(:)';
        [~, frame]=findpeaks(pixel);
        try
            PeakTimeMap(i, j)=min(frame(:));
        catch
        end
%[~, PeakTimeMap(i, j)]=max(Der2ndData(i, j, 42:677));
    end
end

%%%%%%%%%% Deal with abnormal points %%%%%%%%%%
for i=1:row
    for j=1:col
        if PeakTimeMap==0
            try
                PeakTimeMap(i, j)=(PeakTimeMap(i-1, j)+PeakTimeMap(i+1, j)+PeakTimeMap(i, j+1)+PeakTimeMap(i, j-1))/4; % 0 appears in central area
            catch
                if i==1 % 0 appears on the top area
                    if j==1 % 0 appears on the top left corner
                        PeakTimeMap(i, j)=(PeakTimeMap(i+1, j)+PeakTimeMap(i, j+1))/2;
                    elseif j==col % 0 appears on the top right corner
                        PeakTimeMap(i, j)=(PeakTimeMap(i+1, j)+PeakTimeMap(i, j-1))/2;
                    else
                        PeakTimeMap(i, j)=(PeakTimeMap(i-1, j)+PeakTimeMap(i+1, j)+PeakTimeMap(i, j+1))/3;
                    end
               elseif i==row % 0 appears on the bottom area
                    if j==1 % 0 appears on the bottom left corner
                        PeakTimeMap(i, j)=(PeakTimeMap(i-1, j)+PeakTimeMap(i, j+1))/2;
                    elseif j==col % 0 appears on the bottom right corner
                        PeakTimeMap(i, j)=(PeakTimeMap(i-1, j)+PeakTimeMap(i, j-1))/2;
                    else
                        PeakTimeMap(i, j)=(PeakTimeMap(i-1, j)+PeakTimeMap(i, j-1)+PeakTimeMap(i, j+1))/3;
                    end
                else
                    if j==1 % 0 appears on the left side (corners excluded)
                        PeakTimeMap(i, j)=(PeakTimeMap(i-1, j)+PeakTimeMap(i+1, j)+PeakTimeMap(i, j+1))/3;
                    elseif j==col % 0 appears on the right side (corners excluded)
                        PeakTimeMap(i, j)=(PeakTimeMap(i-1, j)+PeakTimeMap(i+1, j)+PeakTimeMap(i, j-1))/3;
                    end
                end
            end
        end
    end
end
%surf(PeakTimeMap);
%pause
for i=1:row
    for j=1:col
        if BinaryMap(i, j) == 0
            PeakTimeMap(i, j) = 0;
        else
            PeakTimeMap(i, j) = (PeakTimeMap(i,j)*3.1416*0.45/25).^0.5*0.1;%% 25 frequency %0.45mm^2/s difussivity
        end
    end
end
%% Reconstruct 3D model
for i=1:row
    for j=1:col
        PeakTimeMap_recon(y1-114+i-1, x1-94+j-1) = PeakTimeMap(i, j);
    end
end
[X, Y] = meshgrid(1:447, 1:303);
X = X.*coefficient;
Y = Y.*coefficient;
save(fullfile(PathName,'PeakTimeMap.mat'), 'PeakTimeMap_recon');
surf(X, Y, PeakTimeMap_recon);
surf2obj(fullfile(PathName,'PeakTimeMap.obj'), X, Y, PeakTimeMap_recon);
close(h);
result = 1;
close all
end
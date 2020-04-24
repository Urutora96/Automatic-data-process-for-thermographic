function [x1, y1, result] = TSR_calculate_coefficient(FileName, PathName)
    if isnumeric(FileName) || isnumeric(PathName)
        result=0;
        return
    else
        p=msgbox('Loading...Please Wait...', 'Processing');
        try
            [RawData,~,~,width,height,FrameNumber,FlashFrame,FrameRate]=OpenThermRawImg2(fullfile(PathName, FileName));
        catch
            close(p);
            result=0;
            return
        end
        FrameRate = round(FrameRate);
        if ((FrameNumber-FlashFrame)/FrameRate) > 20  %% Data duration greater than 20seconds
            FrameNumber = FrameRate*20 + FlashFrame;
            RawData = RawData(:, :, 1:FrameNumber);
            step = floor((FrameRate*20)/6);
        else
            step=floor((FrameNumber-FlashFrame)/6);
        end
        %%%%%%%%%%%% Choose ROI %%%%%%%%%%%%
        f=figure();
        scrsz=get(0, 'ScreenSize');
        set(f, 'Position', scrsz);
        for i=0:5
            subplot(2, 3, i+1);
            imagesc(RawData(:,:,FlashFrame+step*i+floor(FrameRate/2)));
            colormap(jet);
            xlabel('x');
            ylabel('y');
            grid on
            set(gca, 'GridColor', 'r');
            set(gca, 'LineWidth', 1.5);
            set(gca, 'YTick', (0:50:height-1));
            set(gca, 'XTick', (0:50:width-1));
        end
        close(p);
%saveas(gcf,'RawData_t12.png');
        while(1)  
            xy1=inputdlg({'x', 'y'}, 'Select ROI', [1 35], {'150', '150'}, struct('WindowStyle', 'normal'));
            xy2=inputdlg({'x', 'y'}, 'Select ROI', [1 35], {'500', '400'}, struct('WindowsStyle', 'normal'));
            try
                x1=str2double(xy1(1));
                x2=str2double(xy2(1));
                y1=str2double(xy1(2));
                y2=str2double(xy2(2));
            catch
                if isempty(xy1) || isempty(xy2)
                    close all
                    result=0;
                    return
                else
                    h=msgbox('Input Error! Please try again!', 'Error', 'error');
                    waitfor(h)
                    continue
                end
            end
            if x2>x1 && y2>y1 && x1>0 && x2>0 && y1>0 && y2>0 && x1<width && x2<width && y1<height && y2<height
                close all
                p=msgbox('Processing...Please Wait...', 'Processing');
                break
            else
                h=msgbox('Input Error! Please try again!', 'Error', 'error');
                waitfor(h)
            end
        end
%%%%%%%%%%%%cut the image into the ROI %%%%%%%%%%%%%%%%%%%%

        cut_RawData=RawData(y1:y2,x1:x2,12:FrameNumber);%skip the first 12 frames

%%%%%%%% Polynomial Coefficient Calculation & Storage%%%%%%%%%%%%%%%%%%%%%%
%Coefficient_cell=cell(267,362);
%Coefficient1nd_cell=cell(267,362);
%Coefficient2nd_cell=cell(267,362);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        TSRData=zeros(y2-y1+1, x2-x1+1, FrameNumber-12+1);
        Der1stData=zeros(y2-y1+1, x2-x1+1, FrameNumber-12+1);
        Der2ndData=zeros(y2-y1+1, x2-x1+1, FrameNumber-12+1);
        for i=1:y2-y1+1
            for j=1:x2-x1+1
                pixel0=cut_RawData(i, j, :);
                pixelT=pixel0(:)'; %transfer into one dimension array
                pixel_ref=RawData(i+y1-1,j+x1-1,1:9);
                pixel_ref_y=pixel_ref(:)';
                ref_T=mean(pixel_ref_y(1:9));
                %pixelT=pixelT(1:FrameNumber-12+1);
                delta_T=abs(pixelT-ref_T);
                n=1: FrameNumber-12+1;
                t=n/FrameRate;%corresponding time with frame number
                ln_t=log(t);% time in ln domin
                ln_delta_T=log(delta_T);% Temperature in ln domin
                p6=polyfit(ln_t, ln_delta_T, 6);% n degree polynomial fitting
                v6=polyval(p6, ln_t);
                v6=reshape(v6, 1, 1, length(pixelT));
                TSRData(i, j, :)=v6;
            
                p5=polyder(p6);
                v5=polyval(p5, ln_t);
                v5=reshape(v5, 1, 1, length(pixelT));
                Der1stData(i, j, :)=v5;
            
                p4=polyder(polyder(p6));% 2nd derivative coefficient
                v4=polyval(p4, ln_t);
                v4=reshape(v4, 1, 1, length(pixelT));
                Der2ndData(i, j, :)=v4;
            
        %Coefficient_cell{i,j}=p6; % assign coeffiecient to each cell element
        %Coefficient1nd_cell{i,j}=p5;% assign coeffiecient to each cell element
        %Coefficient2nd_cell{i,j}=p4;% assign coeffiecient to each cell element
            
        %v6=polyval(p6, ln_t);
        %plot(ln_t,ln_delta_T, 'o',ln_t,v6, 'r')
        %grid on
        %pause
    
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%   Single Frame Thermogram   %%%%%%%%%%%%%%%%%%
%imagesc(TSRData(:,:,12));
%saveas(gcf,'TSRData_t12.png');
%imagesc( Der1stData(:,:,12));
%saveas(gcf,'1stDerData_t12.png');
%imagesc( Der2stData(:,:,12));
%saveas(gcf,'2stDerData_t12.png');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%pathname=('.\');
%filename=('Coeficient_cell.mat');
%save(pathname,filename,'Coefficient_cell');
        save(fullfile(PathName, 'TSRData.mat'), 'TSRData');
        save(fullfile(PathName, '1stDerData.mat'), 'Der1stData');
        save(fullfile(PathName, '2ndDerData.mat'), 'Der2ndData');
        close(p);
        result=1;
    end
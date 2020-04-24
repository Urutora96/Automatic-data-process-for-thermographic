function [RawTempData,RawTempSub,ColdFrame,width,height,length,FlashFrame,FrameRate] = OpenThermRawImg(file)

%0. Opening raw data (using TWI script)
% input: *.raw data
% output: Data (raw Temp)
fid = fopen(file,'r');

% Skip some info in the begining
fseek(fid,14356,'bof');

%read Frame Width
width = fread(fid,1,'int32');

% Read Frame height
height = fread(fid,1,'int32');

%Read Total Frames
length = fread(fid,1,'int32');

fseek(fid,8,'cof');

%Read Flash Frame
FlashFrame = fread(fid,1,'int32');

fseek(fid,24,'cof');

%Read Frame Rate
FrameRate = fread(fid,1,'double');

% Seek to Data
fseek(fid,14460,'bof');

% Read Data
Data = fread(fid,width*height*length,'int16');
Data = reshape(Data,width,height,length);
fclose(fid);


%0.1. Axesp
FrameNo = 1:1:length;
%Time = 1/FrameRate.*FrameNo;

%1. Allocating data set
RawTempData= zeros(height,width,length);   %New alloc for transposed data
RawTempSub = zeros(size(RawTempData));


%2. Building the new dataset (transposing the Data var)
% input: Data var
% output: DataNew var (transposed old data)

%2.1.!!!!!!!!!!!!!!!!!!!!!!  TRANSPOSING THE IMAGES !!!!!!!!!!!!!!!!!!
for i=1:length
     RawTempData(:,:,i) = Data(:,:,i)';
end

%2.2. Cold Frame   
ColdFrame = mean(RawTempData(:,:,1:FlashFrame-1),3);


function [] = surf2obj(fileName,X, Y, Z)
%
% SURF2OBJ converts a surface into an OBJ file.
%
% SURF2OBJ(fname,X,Y,Z) where fname is the filename (without extension)
% used to generate the dxf file and X, Y and Z are matrix arguments
% of the MATLAB surface format.
% 
% Example: Classical peak plots:
%
% [X,Y,Z] = peaks(3);
% surf2obj('sd.obj',X,Y,Z); % search the file sd.obj at the current MATLAB path
%
%
% Author: Alexandre Carvalho Leite (alexandrecvl@hotmail.com)
% Modified By: Wei Luo, Cranfield University
p=surf2patch(surf(X, Y, Z));
fid=fopen(fileName,'w+');
for v=1:size(p.vertices,1)
    fprintf(fid,'v %f %f %f\n',p.vertices(v,1),p.vertices(v,2),p.vertices(v,3));
end
fprintf(fid,'\n');
for f=1:size(p.faces,1)
    fprintf(fid,'f %d %d %d %d\n',p.faces(f,1),p.faces(f,2),p.faces(f,3),p.faces(f,4));
end
fclose(fid);
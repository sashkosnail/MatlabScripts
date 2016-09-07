P = mfilename('fullpath');

path(strcat(P,'_code'), path);
run(strcat(P,'_code/HVSRgui.m'));
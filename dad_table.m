path = 'D:\Projects\PhD\vibSystem\sensor_data\';
[FileName,PathName,~] = uigetfile(strcat(path, '*.xlsx'),'Pick File');
path=PathName;
res_data = xlsread(strcat(PathName, FileName), 'Details');
num_pts = 4;
num_chans = 1;
fid = fopen(strcat(path, '\', FileName(1:end-4), '_tab_pos.csv'), 'w');
fprintf(fid, 'Channel, Rin, Rsh, Fn, D\n');
i = int32(0);

cdr_data_D = zeros(numel(res), 2);
cdr_data_Fn = zeros(size(cdr_data_D));
for i=1:1:size(res,1)
    Rin = res_data(floor((i-1)/(num_pts*num_chans))+2,mod(floor((i-1)/num_pts),num_chans)+1);
    Rsh = res_data(mod(i-1,num_pts)+7, mod(floor((i-1)/num_pts),num_chans)+19);
    Rdaq = res_data(2,19);
    if(i==1)
        Rtmp = Rdaq;
    else
        Rtmp = Rsh*Rdaq/(Rsh+Rdaq);
    end
    Req = Rin+Rtmp;
    fprintf(fid, '%s, %4.3f, %4.3f, ', res(i,1).Name, Rin, Rsh);
    for j=1:1:size(res,2)
        if(isempty(res(i,j).Name))
            continue
        end
        cdr_data_D((i-1)*size(res,2)+j, :) = [1/Req res(i,j).D];
        cdr_data_Fn((i-1)*size(res,2)+j, :) = [1/Req res(i,j).Fn];
        fprintf(fid, '%6.3f, %6.3f, ', res(i,j).Fn, res(i,j).D);
    end
    fprintf(fid,'\n');
end
fclose(fid);

cdrD = sort(cdr_data_D);
cdrD = cdrD(cdrD(:,1)~=0,:);
cdrF = sort(cdr_data_Fn);
cdrF = cdrF(cdrF(:,1)~=0,:);

ft = fittype(strcat(...
    'A*exp(-D*w0*((n+n0)*Ts))*(D*w0*cos(w0*((n+n0)*Ts)*sqrt(1-D^2)', ...
    '-asin(D))+sin(w0*((n+n0)*Ts)*sqrt(1-D^2)-asin(D))*w0*sqrt(1-D^2))'), ...
    'independent', 'n', 'problem', 'Ts');
fo = fitoptions(ft);
fo.Lower = [0.001, 0.3, 0, 18.85];
fo.Upper = [0.1, 0.9, 0, 31.42];
fo.StartPoint = [0.01, 0.7, 0, 4.5*2*pi];

figure(31);clf
subplot(2,1,1);
plot(cdrD(:,1),cdrD(:,2));
subplot(2,1,2);
plot(cdrF(:,1),cdrF(:,2));
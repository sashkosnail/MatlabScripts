figure(4)
r=50001:1:75000;
comp_data = chan_data(r,:);
dhz = mean([comp_data(:,2) comp_data(:,8)], 2);
dhy = mean([comp_data(:,3) comp_data(:,9)], 2);
dlz = mean([comp_data(:,5) comp_data(:,11)], 2);
dly = mean([comp_data(:,6) comp_data(:,12)], 2);
plot([dhz dlz dhy dly])
Az=std(dhz)/std(dlz);
Ay=std(dhy)/std(dly);
comp_daata_out


Fs = 100;
N = 10000;

k = (0:N-1)';
t = k/Fs;
% f = k*Fs/(2*N);
f = logspace(-1,100, 10^6)';
tab = table;
figure(555); clf
colors = 'kbgrmcy';
for fc = logspace(-.3, 1.5, length(colors));
	tmp = (f./fc).^2;
	for p=0:1:9
		n=2^p;
		Wbpf = (tmp./((1-tmp).^2 + tmp)).^n;

		odb3 = find(Wbpf>2^-.5);
		fidx = [odb3(1:2)-1 odb3(end-1:end)+1];
		ftmp = f(fidx);
		wbpf = Wbpf(fidx);

		dydx = abs(diff(ftmp)./diff(wbpf));

		f3db =  ftmp(1,:) + abs((2^-.5 - wbpf(1,:))).*dydx;
		geomeanf = sqrt(prod(f3db));
		Q = abs(sqrt(prod(f3db))/diff(f3db));
		cQ = sqrt(1/(2^(1/(2*n))-1));
		cn = log(2)/(2*log(1+Q^-2));
		new_row = array2table([fc n cn Q cQ geomeanf mean(f3db)], ...
			'VariableNames', {'Fc', 'n', 'cn', 'Q', 'cQ', 'GeoMeanF', 'MeanF'}); 
		tab = [tab; new_row]; %#ok<AGROW>
		semilogx(f, Wbpf, [colors(mod(p, length(colors))+1) '-'])
		grid on; hold on
		semilogx(f3db, 2^-.5* [1 1], 'kx')
		axis([0.1 50 0 1]);
	end
end
disp(tab)
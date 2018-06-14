function resp = spec_smooth(f,f0,b,D)
    tmp = (f./f0).^2;
%     resp = tmp./((1-tmp).^2+tmp);
    resp = 4*D^2*tmp./((1-tmp).^2+(4*D^2*tmp));
    resp = resp.^b;
end
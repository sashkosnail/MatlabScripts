function M = movmean(A, k, dim)
    if(~exist('dim','var'))
        dim = 1;
    end
    if(length(k)==1); w = ones(k,1); else w = k; end
    w = w/sum(w);
    K = length(w);
    M = zeros(size(A));
    minVal = ceil(K/2);
    maxVal = ceil(length(A)-K/2);
    for n=1:1:length(A)
        W = w;
        if n <= minVal
            start_id = 1;
            end_id = n+floor(K/2);
            W = w(K-end_id+1:end);
            W = W/sum(W);
        elseif (n > minVal) && (n < maxVal)
            start_id = n-ceil(K/2)+1;
            end_id = n+floor(K/2);
        else
            start_id = n-ceil(K/2)+1;
            end_id = length(A);
            W = w(1:end_id-start_id+1);
            W = W/sum(W);
        end
%         disp([num2str(start_id) ' ' num2str(end_id) '||' num2str(W')])
        M(n,:) = sum(A(start_id:end_id,:) .* W, dim);
    end
end
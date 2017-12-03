function b = sortkml(a)
    cells = struct2cell(a); %converts struct to cell matrix
    sortvals = cells(2,1,:); % gets the values of just the first field
    sortvals = reshape(sortvals, length(sortvals), 1);
    aa = regexpi(sortvals,'[0-9]+','match');
    aa = cellfun(@(x) str2double(x{end}), aa);
    bb=(regexpi(sortvals,'[0-9]+N','start'));
    bb = 0.5 * cellfun(@isempty, bb);
    [~, ix] = sort(aa+bb);
    b = a(ix); %rearranges the original array
end
function tickLabel = generateTickLabel(nTicks, labels)
%GENERATE TICK LABEL
%   Generate a cell array of strings as a ticklabel for an axis with tick
%   marks at 1:nTicks, but with labels only required for at the ticks in
%   the vector labels
for idx = 1:nTicks
    if ismember(idx, labels)
        tickLabel{idx} = sprintf('%d', idx);
    else
        tickLabel{idx} = '';
    end
end


function localMode = findLocalModes(count, ridge, gap)
%FINDLOCALMODES find a set of local modes in samples from a distribution
%   counts contains the samples, ridge defines the number of times
%   samples must increase and then decrease to define a mode, and gap
%   defines the proportional increase to define a mode
count = count/sum(count);
localMode = []; maybe = nan;
runUp = 0; runDown = 0; enoughUp = false; enoughDown = false;
for idx = 1:(length(count)-1)
    if count(idx+1) > count(idx)+gap
        runUp = runUp + 1;
        runDown = 0; enoughDown = false;
        if runUp >= ridge
            enoughUp = true;
        end
    elseif count(idx+1) < count(idx)-gap
        if runDown == 0
            maybe = idx;
        end
        runDown = runDown + 1;
        runUp = 0;
        if runDown >= ridge
            enoughDown = true;
        end
    else
        runDown = 0; enoughDown = false;
        runUp = 0; enoughUp = false;
    end
    if enoughUp && enoughDown
        localMode = [localMode maybe];
        enoughUp = false;
        enoughDown = false;
    end
end


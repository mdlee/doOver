function [w, ave] = sjsWeights(x, theta)

nMembers = length(x);
for j = 1:nMembers
    for k =1:nMembers
        f(j, k) = exp(-theta * abs(x(j) - x(k)));
    end
end

for j = 1:nMembers
    wTmp(j) = sum(f(j, :)) - 1;
end

for j = 1:nMembers
    w(j) = wTmp(j)/sum(wTmp);
end

ave = dot(w, x);
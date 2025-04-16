 
function entropy = computeEntropy(distribution)
    entropy = -sum(distribution .* log2(distribution));
end
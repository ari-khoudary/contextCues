function PDF = hazard_rate(N,p)

for i = 1:N
    PDF(i) = ((1-p)^(N-1)) *p;
end


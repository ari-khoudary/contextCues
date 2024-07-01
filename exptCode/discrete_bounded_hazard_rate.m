function p = discrete_bounded_hazard_rate(lambda, N)

% computes a probability distribution defining a fixed hazard rate
% authored by Brian Maniscalco 

p(1) = lambda / (lambda+1);
for i = 2:N-1
    p(i) = (1-sum(p(1:i-1))) * lambda / (lambda+1);
end
p(N) = p(N-1) / lambda;

if sum(p) ~= 1
    error('probability doesn''t sum to 1')
end
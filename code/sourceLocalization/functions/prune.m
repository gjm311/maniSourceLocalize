function [minIdx, mu, cov, min_Q_t] = prune(mu, cov, Q_t, nD, nL)
    minScore = inf;
    Qmu = Q_t*mu;
    
    for n = nL+1:nD
        currScore = norm((Qmu(n,:)/Q_t(n,n)).^2);
        if currScore < minScore
            minIdx = n;
            minScore = currScore;
        end
    end    
    
    Q_t_curr = Q_t;
    Q_t_curr(minIdx,:) = [];
    Q_t_curr(:,minIdx) = [];
    Q_t_curr_row = Q_t;
    Q_t_curr_row(minIdx,:) = [];
    Q_t_div = Q_t(minIdx,minIdx);
    
    min_Q_t = Q_t_curr - (Q_t_curr_row*Q_t_curr_row')/Q_t_div;
    mu(minIdx,:) = [];
    cov(:,minIdx) = [];
    cov(minIdx,:) = [];
end
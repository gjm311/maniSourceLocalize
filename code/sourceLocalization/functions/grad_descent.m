function [tot_cost, vari, scales, varis_set, scales_set] = grad_descent(sourcePos, numArrays, rtfs, cov_init, scales_init, var_init, max_iters, tol, alpha, kern_typ)
    
    nL = size(sourcePos, 1);
    nD = size(rtfs, 1);
    niter = 0; 
    first = 0;
    
    costs = zeros(1,3);

    %x1: cov, x2: varI, x3: pos_coord_vec
    f = @(x1,x2,x3) -.5*x3'*inv(x1+x2)*x3 - max(0,real(.5*log(det(x1+x2)))) - .5*nL*log(2*pi);
    for i = 1:3
        costs(i) = -f(cov_init, var_init*eye(nL), sourcePos(:,i));
    end
    
    prev_cost = inf;
    tot_cost = zeros(1,max_iters);
    varis_set = zeros(1,max_iters);
    scales_set = zeros(max_iters, numArrays);
    
    while or(and(mean(costs)>=tol, niter <= max_iters), mse(prev_cost,mean(costs))>=tol)
        if first == 0
            new_vari = var_init;
            new_varI = new_vari*eye(nL);
            new_cov = cov_init;
            new_scales = scales_init;
            new_gamma = inv(new_cov + new_varI);
            first = 1;
        else
            new_gamma = inv(new_cov + new_varI);
        end
        
        prev_cost = mean(costs);
        dL_dScales = scale_grad(sourcePos, rtfs(1:nL,:,:), numArrays, new_gamma, kern_typ, new_scales);
        dL_dVar = var_grad(sourcePos, new_gamma);
        
        new_scales = new_scales - alpha.*dL_dScales;
        new_vari = new_vari - alpha*dL_dVar;
        
        [~,new_cov] = trCovEst(nL, nD, numArrays, rtfs, kern_typ, new_scales);
        new_varI = new_vari*eye(nL);
        
        for i = 1:3
            costs(i) = -f(new_cov, new_varI, sourcePos(:,i));
        end
        
        niter = niter + 1;
        tot_cost(niter) = mean(costs);
        varis_set(niter) = new_vari;
        scales_set(niter,:) = new_scales; 
    end
    vari = new_vari;
    scales = new_scales;
    
end

function dL_dScales = scale_grad(source_pos, rtfs, numArrays, gamma, kern_typ, scales)
    num_rtfs = size(rtfs,1);
    Ks = zeros(numArrays, num_rtfs, num_rtfs);
    dL_dScales = zeros(1,numArrays);
    for k = 1:numArrays
        for i = 1:num_rtfs
            for j = 1:num_rtfs
                Ks(k,:,:) = Ks(k,:,:) + kernel(rtfs(i,:,k), rtfs(j,:,k), kern_typ, scales(k));
            end
        end
    end
    KL = Ks(:,1:num_rtfs,1:num_rtfs);
    KL_sum = reshape(sum(KL,1), [num_rtfs,num_rtfs]);
    for m = 1:numArrays
        dK_dScale = zeros(num_rtfs,num_rtfs);
        for i = 1:num_rtfs
            for j = 1:num_rtfs
                dK_dScale(i,j) = kern_grad(rtfs(i,:,m), rtfs(j,:,m), kern_typ, scales(m)); 
            end
        end
        dCov_dScale = (1/numArrays^2)*(dK_dScale*KL_sum+KL_sum*dK_dScale);
        dL_dScales(m) = .5*trace(((gamma*source_pos)*(gamma*source_pos)' - gamma)*dCov_dScale);
    end
end


function dL_dVar = var_grad(source_pos, gamma)
    dL_dVar = .5*trace((gamma*source_pos)*(gamma*source_pos)' - gamma);       
end

function k_grad = kern_grad(rtf1, rtf2, kern_typ, scale)
    if strcmp(kern_typ,'gaussian')
        k_grad = (norm(rtf1-rtf2,2)./scale^2) *exp(-norm(rtf1-rtf2,2)./scale);
    end
end
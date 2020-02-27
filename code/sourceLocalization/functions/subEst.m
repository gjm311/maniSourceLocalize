function [sub_scales, num_static, RTF_test, k_t_new, p_hat_t] = subEst(gammaL, posteriors, numMics, numArrays, micsPos, RTF_train, scales, x, rirLen, rtfLen, sourceTrain, sourceTest, nL, nU, T60, c, fs, kern_typ, roomSize)
    %This function finds probabilisitcally static arrays and if this is all
    %arrays (i.e. all arrays static), we compute new RTF sample (based off positioning of all arrays),
    %new test kernel vector (k_t_new) and test position estimate. IF one or
    %more arrays are moving, we update test kernel vector and estimate test
    %position based off sub-network of static arrays. RTF_test of course is
    %still calculated based off positioning of all arrays.
    

    aligned_idxs = find(round(posteriors(:,1)) == 1);
    alignedMic_idxs = aligned_idxs;
    for ms = 1:numMics-1
        alignedMic_idxs = sort(vertcat(alignedMic_idxs*numMics,alignedMic_idxs*numMics-ms));
    end
    
    num_static = size(aligned_idxs,1);
    if size(aligned_idxs,1) == numArrays
       sub_RTF_train = RTF_train; 
       sub_scales = scales; 
       num_static = 0;
       [RTF_test, k_t_new, p_hat_t] = test(x, gammaL, RTF_train, micsPos, rirLen, rtfLen, size(sub_RTF_train,3),...
                numMics, sourceTrain, sourceTest, nL, nU, roomSize, T60, c, fs, kern_typ, sub_scales); 
    else
        drop_idxs = zeros(1,numArrays);
        dropMic_idxs = zeros(1,numArrays*numMics);
        drop_idxs(aligned_idxs) = 1;
        dropMic_idxs(alignedMic_idxs) = 1;
        sub_RTF_train = RTF_train(:,:,~drop_idxs);
        sub_micsPos = micsPos(~dropMic_idxs,:);
        sub_scales = scales(~drop_idxs);
        RTF_test = rtfEst(x, micsPos, rtfLen, numArrays, numMics, sourceTest, roomSize, T60, rirLen, c, fs);
        [~, k_t_new, p_hat_t] = test(x, gammaL, sub_RTF_train, sub_micsPos, rirLen, rtfLen, size(sub_RTF_train,3),...
                numMics, sourceTrain, sourceTest, nL, nU, roomSize, T60, c, fs, kern_typ, sub_scales);  
    end
end
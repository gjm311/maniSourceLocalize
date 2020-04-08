function [opt_tps, opt_fps, opt_tns, opt_fns, max_auc] = paramOpt(sourceTrain, wavs, gammaL, T60, modelMean, modelSd, init_var, lambda, eMax, transMat, RTF_train, nL, nU,rirLen, rtfLen,c, kern_typ, scales, radii,threshes,num_iters, roomSize, radiusU, ref, numArrays, mic_ref, micsPos, numMics, fs)

    num_radii = size(radii, 2);
    num_threshes = size(threshes, 2);
    
    opt_tps = 0;
    opt_fps = 0;
    opt_tns = 0;
    opt_fns = 0;   
    max_auc = 0;
    
    for thr = 1:num_threshes
        thresh = threshes(thr);

        for riter = 1:num_radii
            radius_mic = radii(riter);
            
            tp_ch_curr = 0;
            fp_ch_curr = 0;
            tn_ch_curr = 0;
            fn_ch_curr = 0;

            for iters = 1:num_iters      
                %randomize tst source, new position of random microphone (new
                %position is on circle based off radius_mic), random rotation to
                %microphones, and random sound file (max 4 seconds).
                sourceTest = randSourcePos(1, roomSize, radiusU, ref);
                movingArray = randi(numArrays);
                [~, micsPosNew] = micRotate(roomSize, radius_mic, mic_ref, movingArray, micsPos, numArrays, numMics);
           
    %             wav_folder = wavs(3:27);
                rand_wav = randi(25);
                file = wavs(rand_wav+2).name;
                [x_tst,fs_in] = audioread(file);
                [numer, denom] = rat(fs/fs_in);
                x_tst = resample(x_tst,numer,denom);
                x_tst = x_tst';  


              %---- Initialize subnet estimates of training positions ----
                sub_p_hat_ts = zeros(numArrays, 3); 
                for k = 1:numArrays
                    [subnet, subscales, trRTF] = subNet(k, numArrays, numMics, scales, micsPos, RTF_train);
                    [~,~,sub_p_hat_ts(k,:)] = test(x_tst, gammaL, trRTF, subnet, rirLen, rtfLen, numArrays-1, numMics, sourceTrain,...
                        sourceTest, nL, nU, roomSize, T60, c, fs, kern_typ, subscales);  
                end
                [~, p_fail, ~] = moveDetectorOpt(x_tst, transMat, init_var, lambda, eMax, thresh, gammaL, numMics, numArrays, micsPosNew, 1, 0, sub_p_hat_ts, scales, RTF_train,...
                        rirLen, rtfLen, sourceTrain, sourceTest, nL, nU, roomSize, T60, c, fs, kern_typ);

        %     %---- estimate test positions after movement ----
                [~,~, p_hat_t] = test(x_tst, gammaL, RTF_train, micsPosNew, rirLen, rtfLen, numArrays,...
                                numMics, sourceTrain, sourceTest, nL, nU, roomSize, T60, c, fs, kern_typ, scales);

                local_fail = mean(mean(((sourceTest-p_hat_t).^2)));

                if local_fail > modelMean+modelSd        
                    if p_fail > thresh
                        tp_ch_curr = tp_ch_curr + 1;
                    else
                        fn_ch_curr = fn_ch_curr + 1;
                    end                                                       
                end

                if local_fail < modelMean+modelSd
                    if p_fail > thresh
                        fp_ch_curr = fp_ch_curr + 1;
                    else
                        tn_ch_curr = tn_ch_curr + 1;
                    end
                end
            end
        end
        tps = tp_ch_curr/(num_iters*num_radii);
        fps = fp_ch_curr/(num_iters*num_radii);
        tns = tn_ch_curr/(num_iters*num_radii);
        fns = fn_ch_curr/(num_iters*num_radii);
        
        tpr = tps/(tps+fns);
        fpr = fps/(fps+tns);
        auc_curr = trapz(fpr,tpr);
        
        if auc_curr>max_auc
           opt_tps = tp_ch_curr;
           opt_fps = fp_ch_curr;
           opt_tns = tn_ch_curr;
           opt_fns = fn_ch_curr;
           max_auc = auc_curr;
        end
        
    end
end
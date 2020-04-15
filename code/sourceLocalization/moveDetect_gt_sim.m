clear
addpath ./RIR-Generator-master
addpath ./functions
mex -setup c++
mex RIR-Generator-master/rir_generator.cpp;
addpath ./stft
addpath ./shortSpeech

%{
This program looks at the localization error (MSE) of arrays when moved 
varying distances from where they originated (i.e. for training). The
purpose is to see the correspondance between the localization error with
the proabilities of failure of the MRF based movement detector.
%}

% ---- TRAINING DATA ----
% room setup
disp('Setting up the room');
% ---- Initialize Parameters for training ----

%---- load training data (check mat_trainParams for options)----
% load('mat_outputs/biMicCircle_5L300U_monoNode')
% micRTF_trains = RTF_train;
% micScales = scales;
% micGammaLs = gammaLs;

load('mat_outputs/monoTestSource_biMicCircle_5L300U_2')
% load('mat_results/vari_t60_data.mat')
% load('mat_outputs/movementOptParams')
ts = [1 4 8];

% simulate different noise levels
radii = 0:.03:.13;
num_radii = size(radii,2);
mic_ref = [3 5.75 1; 5.75 3 1; 3 .25 1; .25 3 1];
wavs = dir('./shortSpeech/');

%---- Set MRF params ----
transMat = [.65 0.3 0.05; .2 .75 0.05; 1/3 1/3 1/3];
init_var = .2;
lambda = .3;
eMax = .3;
threshes = 0:.1:1;
num_threshes = size(threshes,2);
num_iters = 1;
num_ts = size(T60s,2);
t_str = ([]);
gts = 0:.15:.6;
num_gts = size(gts,2);

% for t = 1:num_ts
t = 1;
t_curr = ts(t);
T60 = T60s(t);
RTF_train = reshape(RTF_trains(t_curr,:,:,:), [nD, rtfLen, numArrays]);    
scales = scales_t(t_curr,:);
gammaL = reshape(gammaLs(t_curr,:,:), [nL, nL]);
%     micRTF_train = reshape(micRTF_trains(t,:,:,:), [numArrays, nD, rtfLen, numMics]);
%     micScale = reshape(micScales(t,:,:), [numArrays,numMics]);
%     micGammaL = reshape(micGammaLs(t,:,:,:), [numArrays,nL,nL]);

for g = 1:num_gts
    gt = radii(g);
    for thr = 1:num_threshes 
        thresh = threshes(num_threshes);
%             naive_thresh = naive_threshes(thr);
%             sub_thresh = sub_threshes(thr);

        mrf_res = gtVary(thresh, sourceTrain, wavs, gammaL, T60, gt, init_var, lambda, eMax, transMat, RTF_train, nL, nU,rirLen, rtfLen,c, kern_typ, scales, radii,threshes,num_iters, roomSize, radiusU, ref, numArrays, mic_ref, micsPos, numMics, fs);

%             t_str(t,thr).tp_check = mrf_res(1);
%             t_str(t,thr).fp_check = mrf_res(2);
%             t_str(t,thr).tn_check = mrf_res(3);
%             t_str(t,thr).fn_check = mrf_res(4);
        t_str(g,thr).tp = mrf_res(1);
        t_str(g,thr).fp = mrf_res(2);
        t_str(g,thr).tn = mrf_res(3);
        t_str(g,thr).fn = mrf_res(4);
        t_str(g,thr).tpr = mrf_res(1)/(mrf_res(1)+mrf_res(4)+10e-6);
        t_str(g,thr).fpr = mrf_res(2)/(mrf_res(2)+mrf_res(3)+10e-6);
      
%         t_str(t,thr).nai_tp_check = nai_res(1);
%         t_str(t,thr).nai_fp_check = nai_res(2);
%         t_str(t,thr).nai_tn_check = nai_res(3);
%         t_str(t,thr).nai_fn_check = nai_res(4);
% 
%         t_str(t,thr).subNai_tp_check = sub_res(1);
%         t_str(t,thr).subNai_fp_check = sub_res(2);
%         t_str(t,thr).subNai_tn_check = sub_res(3);
%         t_str(t,thr).subNai_fn_check = sub_res(4);

    end
    break
    save('mat_results/gt_results', 't_str') 
end   
% end

% save('mat_results/thresh_res')

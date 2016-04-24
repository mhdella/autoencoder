%% RESET
clear; clc;
cd '/Users/jordanburgess/Dropbox/MLSALT/mlsalt4 Advanced Machine Learning/autoencoder';
addpath mnist;

images = loadMNISTImages('./mnist/train-images-idx3-ubyte');
labels = loadMNISTLabels('./mnist/train-labels-idx1-ubyte');
rng(568);

%% INITIALISE
% x = [images(:,labels==3) images(:,labels==7)];
x = images;

nInput = size(x, 1);
dbn.sizes = [nInput, 256, 3]; % Hidden states (square number helpful for visualisation)
opts.nEpochs = 4;
opts.nBatchSize = 128;
opts.momentum = 0.6;
opts.l2 = 0.00002;  % Paper subtracts 0.00002*weight from weight

for layer = 1 : numel(dbn.sizes) - 1
    dbn.rbm{layer}.W  = 0.1*randn(dbn.sizes(layer + 1), dbn.sizes(layer));
    dbn.rbm{layer}.a  = zeros(dbn.sizes(layer), 1);
    dbn.rbm{layer}.b  = zeros(dbn.sizes(layer + 1), 1);
    dbn.rbm{layer}.hiddenUnits = 'logistic';
    dbn.rbm{layer}.learningRate = 0.1;
end
% Code layer is linear with Gaussian noise
dbn.rbm{end}.hiddenUnits = 'linear';
dbn.rbm{end}.learningRate = 0.001;

%% TRAIN
dbn.rbm{1} = rbmtrain(dbn.rbm{1}, x, opts);
visualiseweights(dbn.rbm{1}.W');

for layer = 2 : numel(dbn.rbm)
    x = rbmup(dbn.rbm{layer - 1}, x);
    dbn.rbm{layer} = rbmtrain(dbn.rbm{layer}, x, opts);
    visualiseweights(dbn.rbm{layer}.W);
end

%% UNROLL
nn = dbnunroll(dbn);

%% RECONSTRUCT
x = images;
X = nnfeedforward(nn, x);
kk = randperm(size(x, 2));
i = 1;
i = i +1; visualisereconstruction(X{1}(:,kk(i)), X{end}(:,kk(i)));

%% FINETUNE
% Mini-batch gradient descent with reconstruction mean squared error
opts.nEpochs = 1;
opts.nBatchSize = 128;
opts.momentum = 0.6;
opts.l2 = 0.00002;
opts.learningRate = 0.01;

x = images;
nn = nntrain(nn, x, x, opts);

%% RECONSTRUCT
% x = [images(:,labels==3) images(:,labels==7) images(:,labels==5)];
% labs = [labels(labels==3); labels(labels==7); labels(labels==5)];
nSamples = 1000;
x = images(:,1:nSamples);
labs = labels(1:nSamples);

X = nnfeedforward(nn, x);
kk = randperm(size(x,2));
i = 1;
i = i +1; visualisereconstruction(X{1}(:,kk(i)), X{end}(:,kk(i)));

%% VISUALISE
figure(3);
hold off;

% Should this use RBMs with binary states etc?
for i = 0:9
    x = images(:, labels==i);
    x = x(:, 1:nSamples);
%     X = nnfeedforward(nn, x);
    x1 = x;
    x2 = rbmupsigmoidbin(nn.rbm{1}, x1);
    x3 = rbmuplinear(nn.rbm{2}, x2);
    figure(3);
    s{i+1} = scatter3(x3(1,:), x3(2,:), x3(3,:));
    hold on;
    pause(2)
end

classdef customClassificationLayer < nnet.layer.ClassificationLayer
        
    properties
        % (Optional) Layer properties.

        % Layer properties go here.
        ClassWeights
    end
 
    methods
        function layer = customClassificationLayer(Name, classWeights)           
            % (Optional) Create a myClassificationLayer.

            % Layer constructor function goes here.
            layer.Name = Name;
            layer.ClassWeights = classWeights;
        end

        function loss = forwardLoss(layer, Y, T)
            % Return the loss between the predictions Y and the training 
            % targets T.
            %
            % Inputs:
            %         layer - Output layer
            %         Y     – Predictions made by network
            %         T     – Training targets
            %
            % Output:
            %         loss  - Loss between Y and T
            keyboard
            N = size(Y,4);
            Y = squeeze(Y);
            T = squeeze(T);
            
            W = unetwmap(T(:,:,2),10,25);
            %Repeat weights in Z to make correct size
            W = cat(3, W, W);
            
%             loss = -sum(W.*(T.*log(Y)))/N;
            loss = -sum((W.*(T.*log(Y))/N), 'all');

%             keyboard
%              N = size(Y,4);
%             Y = squeeze(Y);
%             T = squeeze(T);
%             W = layer.ClassWeights;
%             W = W';
%     
%             loss = -sum(W*(T.*log(Y)))/N;
            
        end

%         function dLdY = backwardLoss(layer, Y, T)
%             % dLdY = backwardLoss(layer, Y, T) returns the derivatives of
%             % the weighted cross entropy loss with respect to the
%             % predictions Y.
%             keyboard
%             [~,~,K,N] = size(Y);
%             Y = squeeze(Y);
%             T = squeeze(T);
%             W = layer.ClassWeights;
% 			
%             dLdY = -(W'.*T./Y)/N;
%             dLdY = reshape(dLdY,[1 1 K N]);
%         end
    end
end
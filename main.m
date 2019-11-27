clear all; close all;
% 'apples.png', 'brick.jpg', 'grass.png', 'radishes.jpg', 'random3.png',
% 'rice.bmp', 'toast.png', 'weave.jpg', 'random.png'
img_list = {'text.jpg'};% 
for i = 1:length(img_list)
    part1(img_list{i}, 0.1, 1/6);
    part1(img_list{i}, 0.4, 1/6);
    part1(img_list{i}, 0.8, 1/6);
    part1(img_list{i}, 0.1, 1/2);
    part1(img_list{i}, 0.4, 1/2);
    part1(img_list{i}, 0.8, 1/2); 
end



% part2('al.jpg', 'rice.bmp'  , 0.5, 3, 0.4);
% part2('al.jpg', 'toast.png' , 0.5, 3, 0.4);
% part2('ml.jpg', 'rice.bmp'  , 0.5, 3, 0.4);
% part2('ml.jpg', 'toast.png' , 0.5, 3, 0.4);
% 
% part2('al.jpg', 'rice.bmp'  , 0.1, 3, 0.4);
% part2('al.jpg', 'toast.png' , 0.1, 3, 0.4);
% part2('ml.jpg', 'rice.bmp'  , 0.1, 3, 0.4);
% part2('ml.jpg', 'toast.png' , 0.1, 3, 0.4);

% part2('al.jpg', 'rice.bmp'  , 0.9, 3, 0.4);
% part2('al.jpg', 'toast.png' , 0.9, 3, 0.4);
% part2('ml.jpg', 'rice.bmp'  , 0.9, 3, 0.4);
% part2('ml.jpg', 'toast.png' , 0.9, 3, 0.4);




% parameter : apple 70,70
%% Part1: Texture Synthesis 
function part1(image_name, patch_size, overlap_ratio, out_scale, tol_ratio)
    texture = imread(['./textures/',image_name]); 
    t_size = size(texture); 

    % parameters   
    if ~exist('patch_size', 'var') || isempty(patch_size), patch_size = 0.3; end
    if ~exist('overlap_ratio', 'var'), overlap_ratio = 1/6;end % 0 ~ 1 of patch size
    if ~exist('out_scale', 'var'), out_scale = [5, 5];end % h, w/
    if ~exist('tol_ratio', 'var'), tol_ratio = 0.1; end 
    
    % init 
    if length(patch_size) <= 1, patch_size = round(patch_size .* t_size(1:2));end
    file_name = ['./results/', 'part1_', image_name(1:end-4),  ...
                 '_',num2str(patch_size(1)), 'x', num2str(patch_size(2)), ...
                 '_', num2str(overlap_ratio), '_tl', num2str(tol_ratio)];
    % Method 1 Random
    mode = "random"; 
    quilted1 = texture_quilting(texture, out_scale, patch_size, mode, overlap_ratio, tol_ratio) ;
    imwrite(quilted1, char(strjoin([file_name, '_', mode, '.png'], ''))); 
    
    % Method 2 Ovelap
    mode = "overlap"; 
    quilted2 = texture_quilting(texture, out_scale, patch_size, mode, overlap_ratio, tol_ratio) ;
    imwrite(quilted2, char(strjoin([file_name, '_', mode, '.png'], ''))); 
    
    % Method 3 MinCut 
    mode = "mincut"; 
    quilted3 = texture_quilting(texture, out_scale, patch_size, mode, overlap_ratio, tol_ratio) ;
    imwrite(quilted3, char(strjoin([file_name, '_', mode, '.png'], ''))); 
        
    % show comparison
    mode = "all"; 
    f = figure(1); 
    montage({quilted1, quilted2, quilted3}, 'Size', [1 3], 'BorderSize', 10, 'BackgroundColor', 'w');
    saveas(f,char(strjoin([file_name, '_', mode, '.png'], '')));  

end

%% Part2: Testure Transfer
function part2(src_name, txt_name,  alpha, n_iter, patch_size, overlap_ratio, tol_ratio)
    source = imread(['./images/', src_name]); 
    texture = imread(['./textures/',txt_name]); 
    t_size = size(texture); 

    % parameters   
    if ~exist('patch_size', 'var') || isempty(patch_size), patch_size = 0.3; end
    if ~exist('overlap_ratio', 'var'), overlap_ratio = 1/6;end % 0 ~ 1 of patch size
    if ~exist('tol_ratio', 'var'), tol_ratio = 0.1; end 
    if ~exist('alpha', 'var'), alpha = 0.2; end 
    if ~exist('n_iter', 'var'), n_iter = 1; end 
    
    % init 
    if length(patch_size) <= 1, patch_size = round(patch_size .* t_size(1:2));end
    file_name = ['./results/', 'part2_', src_name(1:end-4), '_', txt_name(1:end-4), ...
                 '_',num2str(patch_size(1)), 'x', num2str(patch_size(2)), ...
                 '_', num2str(overlap_ratio),'_tl', num2str(tol_ratio),  '_al', num2str(alpha)];
    
    % iterative 
    mode = "mincut"; 
    [transfered, trans_list] = texture_transfer(texture, source, patch_size, mode, overlap_ratio, tol_ratio, alpha, n_iter, file_name);
    f = figure(2);
    montage(trans_list, 'Size', [1, n_iter+1],  'BorderSize', 10, 'BackgroundColor', 'w');
    saveas(f,char(strjoin([file_name, '_', mode, '.png'], '')));  
end


function [transfered, transfered_list] = texture_transfer(texture, source, patch_size, mode, overlap_ratio, tol_ratio, alpha, n_iter, file_name)
    % iterative 
    error = [];
    transfered_list = cell(1, n_iter+1);
    transfered_list{1} = source; 
    for i = 1:n_iter
        [transfered, error] = quilt_on_image(texture, source, patch_size, mode, overlap_ratio, tol_ratio, alpha, error); 
        imwrite(transfered, char(strjoin([file_name, '_', mode, '_iter',num2str(i), '.png'], ''))); 
        transfered_list{i+1} = transfered; 
        % update param for next iter 
        patch_size = round(patch_size ./ 3.0); 
        if n_iter > 1, alpha = min(alpha + 0.8*(i-1)/(n_iter-1), 1); end
    end
end

function [transfered, error_prev] = quilt_on_image(texture, source, patch_size, mode, overlap_ratio, tol_ratio, alpha, error)
    % read texture sample as double
    texture = im2double(texture);
    source  = im2double(source); 
    
    % define parameter size 
    txt_size = size(texture);
    out_size = size(source);
    p_o_size = [patch_size(1), patch_size(2), txt_size(3)]; 
%     p_o_size = [round(txt_size(1:2).*patch_ratio), txt_size(3)];    % patch with overlap size (patch+ovl) 
    ovl_size = [round(p_o_size(1:2).*overlap_ratio), txt_size(3)];  % overlaped region 
    pth_size = [p_o_size - ovl_size, txt_size(3)];                  % patch size 
   
    % initialize error from prev 
    if isempty(error), error_prev = zeros(txt_size(1:2));
    else, error_prev = error;
    end
    
    % quilt patches 
    transfered = zeros(out_size); 
    for r = 1 : pth_size(1) : out_size(1)
        r_end = min(out_size(1), r+pth_size(1)-1); 
        for c = 1: pth_size(2) : out_size(2)
            c_end = min(out_size(2), c+pth_size(2)-1); 
            % patch size based on output 
            p_r_end = min(pth_size(1), out_size(1)-r+1); 
            p_c_end = min(pth_size(2), out_size(2)-c+1);
            % get contecnt patch from source 
            src_patch = source(r:r_end, c:c_end, :);
            % overlap based on the location
            o_r_start = max(1, r-ovl_size(1)); 
            o_c_start = max(1, c-ovl_size(2)); 
            v_ovl = transfered(o_r_start:r_end, o_c_start:c,:); % vertical overlap 
            h_ovl = transfered(o_r_start:r, o_c_start:c_end,:); % horizontal overlap
            
            if strcmpi(mode, 'random') 
                [patch, ~, error_prev] = sample_patch_on_image(texture, src_patch, [], [], alpha, tol_ratio, error_prev); 
                transfered(r:r_end, c:c_end, :) = patch(1:p_r_end, 1:p_c_end, :); 
            else % overlap
                [patch, txt_loc, error_prev] = sample_patch_on_image(texture, src_patch, v_ovl, h_ovl, alpha, tol_ratio, error_prev); 
                transfered(r:r_end, c:c_end, :) = patch(1:p_r_end, 1:p_c_end, :); 
                if strcmpi(mode, 'mincut')
                   patch_ovl = blend_mincut(texture, txt_loc, v_ovl, h_ovl); 
                   transfered(o_r_start:r_end, o_c_start:c_end, :) = patch_ovl; 
                end
            end
        end
    end
end



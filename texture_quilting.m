function quilted = texture_quilting(texture, out_scale, patch_size, mode, overlap_ratio, tol_ratio)
    % read texture sample as double
    texture = im2double(texture);
    
    % define parameter size 
    txt_size = size(texture);
    out_size = [round(txt_size(1:2).*out_scale)]; 
    if (length(txt_size) >= 3), out_size = [round(txt_size(1:2).*out_scale), txt_size(3)];end
    p_o_size = [patch_size(1), patch_size(2)]; 
%     p_o_size = [round(txt_size(1:2).*patch_ratio)];    % patch with overlap size (patch+ovl) 
    ovl_size = [round(p_o_size(1:2).*overlap_ratio)];  % overlaped region 
    pth_size = [p_o_size - ovl_size];                  % patch size 
   
   
    % quilt patches 
    quilted = zeros(out_size); 
    for r = 1 : pth_size(1) : out_size(1)
        r_end = min(out_size(1), r+pth_size(1)-1); 
        for c = 1: pth_size(2) : out_size(2)
            c_end = min(out_size(2), c+pth_size(2)-1); 
            % patch size based on output 
            p_r_end = min(pth_size(1), out_size(1)-r+1); 
            p_c_end = min(pth_size(2), out_size(2)-c+1);
            patch_size = [p_r_end, p_c_end]; 
            % overlap based on the location
            o_r_start = max(1, r-ovl_size(1)); 
            o_c_start = max(1, c-ovl_size(2)); 
            v_ovl = quilted(o_r_start:r_end, o_c_start:c,:); % vertical overlap 
            h_ovl = quilted(o_r_start:r, o_c_start:c_end,:); % horizontal overlap
            
            if strcmpi(mode, 'random') 
                [patch, ~] = sample_patch(texture, patch_size, [], [], tol_ratio); 
                 quilted(r:r_end, c:c_end, :) = patch(1:p_r_end, 1:p_c_end, :); 
            else % overlap
                [patch, txt_loc] = sample_patch(texture, patch_size, v_ovl, h_ovl, tol_ratio); 
                quilted(r:r_end, c:c_end, :) = patch(1:p_r_end, 1:p_c_end, :);         
                if strcmpi(mode, 'mincut') && (o_r_start > 1 || o_c_start > 1)
                   patch_ovl = blend_mincut(texture, txt_loc, v_ovl, h_ovl); 
                   quilted(o_r_start:r_end, o_c_start:c_end, :) = patch_ovl; 
                end
            end
        end
    end
end



function [patch, txt_loc] = sample_patch(texture, patch_size, v_ovl, h_ovl, tol_ratio)
    t_size = size(texture);
    [p_o_height, ovl_c, ~] = size(v_ovl); % [(ovl_r + patch_r), ovl_c] 
    [ovl_r, p_o_width, ~]  = size(h_ovl); % [ovl_r, (ovl_c + patch_c)]  
    
    % if no overlap, return randomly sampled patch 
    if ovl_c <= 1 && ovl_r <= 1
        if t_size(1)~=patch_size(1), row = randi(t_size(1)-patch_size(1)); else, row=1; end 
        if t_size(2)~=patch_size(2), col = randi(t_size(2)-patch_size(2)); else, col=1; end 
        patch = texture(row:row-1+patch_size(1), col:col-1+patch_size(2),:);  
        txt_loc = [row, col];
        return 
    end
    
    % compute ssd error at each pixel of texture with horizontal ovl 
    ssd_patch = ones(t_size(1:2)).*Inf; 
    for r = 1:t_size(1)-p_o_height% make sure including all region 
        for c = 1:t_size(2)-p_o_width
            if ovl_c <= 1, ssd_v = 0; 
            else, ssd_v = compute_ssd(texture(r:r-1+p_o_height,c:c-1+ovl_c,:), v_ovl);
            end 
            if ovl_r <= 1, ssd_h = 0; 
            else, ssd_h = compute_ssd(texture(r:r-1+ovl_r,c:c-1+p_o_width,:), h_ovl); 
            end
            ssd_patch(r,c) = ssd_v + ssd_h; 
        end
    end
    
    % sample patch among topk
    tolerance = min(ssd_patch(:)) + tol_ratio* min(ssd_patch(:));
    
    [topk_r, topk_c] = find((ssd_patch <= tolerance)&(ssd_patch ~= Inf)); 
    r_idx = randi(length(topk_r)); 
    row = topk_r(r_idx);
    col = topk_c(r_idx); 
    txt_loc = [row, col];
    % return patch without overlap
    row_ovl = row+ovl_r; 
    col_ovl = col+ovl_c; 
    patch =  texture(row_ovl:row_ovl-1+patch_size(1), col_ovl:col_ovl-1+patch_size(2),:); 
end


function ssd = compute_ssd(patch1, patch2)
    % compute sum of squared difference 
    diff = (patch1-patch2).^2; 
    ssd = sum(diff(:)) / length(diff(:)); 
end
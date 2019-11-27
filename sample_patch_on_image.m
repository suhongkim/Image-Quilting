function [patch, txt_loc, error_prev] = sample_patch_on_image(texture, src_patch, v_ovl, h_ovl, alpha, tol_ratio, error_prev)
    t_size = size(texture);
    p_size = size(src_patch); 
    [p_o_height, ovl_c, ~] = size(v_ovl); % [(ovl_r + patch_r), ovl_c] 
    [ovl_r, p_o_width, ~]  = size(h_ovl); % [ovl_r, (ovl_c + patch_c)]  
    
    % if no overlap, return randomly sampled patch 
    if ovl_c <= 1 && ovl_r <= 1
        if t_size(1)~=p_size(1), row = randi(t_size(1)-p_size(1)); else, row=1; end 
        if t_size(2)~=p_size(2), col = randi(t_size(2)-p_size(2)); else, col=1; end 
        patch = texture(row:row-1+p_size(1), col:col-1+p_size(2),:);  
        txt_loc = [row, col];
        return 
    end
    
    % compute ssd error on image 
    ssd_src = ones(t_size(1:2)).*Inf; 
    for r = 1:t_size(1)-p_size(1)% make sure including all region 
        for c = 1:t_size(2)-p_size(2)
            ssd_src(r,c) = compute_ssd(texture(r:r-1+p_size(1),c:c-1+p_size(2),:), src_patch); 
        end
    end
    
    % compute ssd error on overlap
    ssd_ovl = ones(t_size(1:2)).*Inf; 
    for r = 1:t_size(1)-p_o_height
        for c = 1:t_size(2)-p_o_width
            if ovl_c <= 1, ssd_v = 0; 
            else, ssd_v = compute_ssd(texture(r:r-1+p_o_height,c:c-1+ovl_c,:), v_ovl);
            end 
            if ovl_r <= 1, ssd_h = 0; 
            else, ssd_h = compute_ssd(texture(r:r-1+ovl_r,c:c-1+p_o_width,:), h_ovl); 
            end
            ssd_ovl(r,c) = ssd_v + ssd_h; 
        end
    end
    
    % blend error with alpha 
    ssd_patch = (1-alpha).*ssd_src + alpha.*(ssd_ovl+error_prev);
    error_prev = ssd_patch;  
    
    % sample patch under tolerance 
    tolerance = min(ssd_patch(:)) + tol_ratio* min(ssd_patch(:));
    [topk_r, topk_c] = find((ssd_patch <= tolerance)&(ssd_patch ~= Inf)); 
    if  isempty(topk_r)
        [topk_r, topk_c] = find(ssd_patch ~= Inf); 
        
    end
    r_idx = randi(length(topk_r));
    row = topk_r(r_idx);
    col = topk_c(r_idx); 
    txt_loc = [row, col];
    
    % return patch without overlap
    row_ovl = row+ovl_r; 
    col_ovl = col+ovl_c; 
    try
        patch =  texture(row_ovl:row_ovl-1+p_size(1), col_ovl:col_ovl-1+p_size(2),:); 
    catch Me
        disp(' here '); 
    end
end 


function ssd = compute_ssd(patch1, patch2)
    % compute sum of squared difference 
    diff = (patch1-patch2).^2; 
    ssd = sum(diff(:)) / length(diff(:)); 
end

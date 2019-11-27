function quilted = quilting_overlap(texture, out_scale, patch_ratio, overlap_ratio, topk)
    % read texture sample as double
    texture = im2double(texture);
    % define parameter size 
    txt_size = size(texture);
    out_size = [round(txt_size(1:2).*out_scale), txt_size(3)];
    p_o_size  = [round(txt_size(1:2).*patch_ratio), txt_size(3)]; % search size (patch+ovl) 
    ovl_size = [round(p_o_size(1:2).*overlap_ratio), txt_size(3)]; % overlap diff 
    pth_size = [p_o_size - ovl_size, txt_size(3)]; % actual patch size 
   
    % quilt patches 
    quilted = zeros(out_size); 
    for r = 1 : pth_size(1) : out_size(1)
        r_end = min(out_size(1), r+pth_size(1)-1); 
        for c = 1: pth_size(2) : out_size(2)
            c_end = min(out_size(2), c+pth_size(2)-1); 
            % patch size based on output 
            p_r_end = min(pth_size(1), out_size(1)-r+1); 
            p_c_end = min(pth_size(2), out_size(2)-c+1);
            % sample patch 
            if r == 1 && c == 1  % non-overlap 
                patch = sample_patch_randomly(texture, [p_r_end, p_c_end]);
            else
                % overlap based on the location
                o_r_start = max(1, r-ovl_size(1)); 
                o_c_start = max(1, c-ovl_size(2)); 
                v_ovl = quilted(o_r_start:r_end, o_c_start:c,:); % vertical overlap 
                h_ovl = quilted(o_r_start:r, o_c_start:c_end,:); % horizontal overlap
                patch = sample_patch_overlap(texture, [p_r_end, p_c_end], v_ovl, h_ovl, topk);     
            end
            quilted(r:r_end, c:c_end, :) = patch(1:p_r_end, 1:p_c_end, :); 
        end
    end
end

function patch = sample_patch_randomly(texture, patch_size)
    t_size = size(texture); 
    if t_size(1)~=patch_size(1), row = randi(t_size(1)-patch_size(1)); else row=1;, end; 
    if t_size(2)~=patch_size(2), col = randi(t_size(2)-patch_size(2)); else col=1;, end; 
    patch = texture(row:row-1+patch_size(1), col:col-1+patch_size(2),:); 
end
 
function patch = sample_patch_overlap(texture, p_size, v_ovl, h_ovl, topk)
    t_size = size(texture);
    [p_o_height, ovl_c, ~] = size(v_ovl); % [(ovl_r + patch_r), ovl_c] 
    [ovl_r, p_o_width, ~]  = size(h_ovl); % [ovl_r, (ovl_c + patch_c)] 
     
    % compute ssd error at each pixel of texture with horizontal ovl 
    ssd_patch = ones(t_size(1:2)).*Inf; 
    for r = 1:t_size(1)-p_o_height% make sure including all region 
        for c = 1:t_size(2)-p_o_width
            ssd_v = compute_ssd(texture(r:r-1+p_o_height,c:c-1+ovl_c,:), v_ovl);
            if ovl_c <= 1, ssd_v = 0; end
            ssd_h = compute_ssd(texture(r:r-1+ovl_r,c:c-1+p_o_width,:), h_ovl); 
            if ovl_r <= 1, ssd_h = 0; end
            ssd_patch(r,c) = ssd_v + ssd_h; 
        end
    end
    % sample patch among topk
%     tolerance = max(mink(ssd_patch(:), topk)); 
    tolerance = min(ssd_patch(:)) + 0.1* min(ssd_patch(:));

    [topk_r, topk_c] = find((ssd_patch <= tolerance)&(ssd_patch ~= Inf)); 
    r_idx = randi(length(topk_r)); 
    if t_size(1)~=p_o_height, row = topk_r(r_idx); else row=1; end 
    if t_size(2)~=p_o_width, col = topk_c(r_idx);  else col=1; end 
    
    % return patch without overlap 
    row = row + ovl_r; 
    col = col + ovl_c; 
    
    patch = texture(row:row-1+p_size(1), col:col-1+p_size(2),:); 
end

function ssd = compute_ssd(patch1, patch2)
    % compute sum of squared difference 
    diff = (patch1-patch2).^2; 
    ssd = sum(diff(:)) / length(diff(:)); 
end
function [quilted, error_prev] = texture_transfer1(texture, source, patch_ratio, overlap_ratio, alpha, error)
    % read texture sample as double
    texture = im2double(texture);
    source  = im2double(source); 
    
    % define parameter size 
    txt_size = size(texture);
    out_size = size(source);
    p_o_size  = [round(txt_size(1:2).*patch_ratio), txt_size(3)]; % search size (patch+ovl) 
    ovl_size = [round(p_o_size(1:2).*overlap_ratio), txt_size(3)]; % overlap diff 
    pth_size = [p_o_size - ovl_size, txt_size(3)]; % actual patch size 
   
    % initialize error from prev 
    if isempty(error), error_prev = zeros(txt_size(1:2));
    else, error_prev = error;
    end
    
    % quilt patches 
    quilted = zeros(out_size); 
    for r = 1 : pth_size(1) : out_size(1)
        r_end = min(out_size(1), r+pth_size(1)-1); 
        for c = 1: pth_size(2) : out_size(2)
            c_end = min(out_size(2), c+pth_size(2)-1); 
            % patch size based on output 
            p_r_end = min(pth_size(1), out_size(1)-r+1); 
            p_c_end = min(pth_size(2), out_size(2)-c+1);
            src_patch = source(r:r_end, c:c_end, :);
            % sample patch 
            if r == 1 && c == 1  % non-overlap 
                patch_src = sample_patch_on_image(texture, src_patch, [], [], alpha, error_prev);
                quilted(r:r_end, c:c_end, :) = patch_src;
            else
                % overlap based on the location
                o_r_start = max(1, r-ovl_size(1)); 
                o_c_start = max(1, c-ovl_size(2)); 
                v_ovl = quilted(o_r_start:r_end, o_c_start:c,:); % vertical overlap 
                h_ovl = quilted(o_r_start:r, o_c_start:c_end,:); % horizontal overlap
                [patch_ovl, error_prev] = sample_patch_on_image(texture, src_patch, v_ovl, h_ovl, alpha, error_prev); 
                quilted(o_r_start:r_end, o_c_start:c_end, :) = patch_ovl; 
            end
        end
    end
end

function [patch, error_prev] = sample_patch_on_image(texture, src_patch, v_ovl, h_ovl, alpha, error_prev)
    t_size = size(texture);
    p_size = size(src_patch); 
    [p_o_height, ovl_c, ~] = size(v_ovl); % [(ovl_r + patch_r), ovl_c] 
    [ovl_r, p_o_width, ~]  = size(h_ovl); % [ovl_r, (ovl_c + patch_c)]  
    
    % compute ssd error at each pixel of texture with horizontal ovl 
    ssd_src = ones(t_size(1:2)).*Inf; 
    for r = 1:t_size(1)-p_size(1)% make sure including all region 
        for c = 1:t_size(2)-p_size(2)
            ssd_src(r,c) = compute_ssd(texture(r:r-1+p_size(1),c:c-1+p_size(2),:), src_patch); 
        end
    end
    
    % compute ssd error at each pixel of texture with horizontal ovl
    ssd_ovl = ones(t_size(1:2)).*Inf; 
    for r = 1:t_size(1)-p_o_height% make sure including all region 
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
    ssd_patch = (1-alpha).*ssd_src + alpha*(ssd_ovl+error_prev); 
    error_prev = ssd_patch;
    
    % sample patch among topk
%     tolerance = max(mink(ssd_patch(:), topk)); 
    tolerance = min(ssd_patch(:)) + 0.1* min(ssd_patch(:));
    [topk_r, topk_c] = find((ssd_patch <= tolerance)&(ssd_patch ~= Inf)); 
    r_idx = randi(length(topk_r)); 
    row = topk_r(r_idx);
    col = topk_c(r_idx); 
%     disp(ssd_patch(row, col)); 
    
    if isempty(v_ovl) && isempty(v_ovl)
        patch = texture(row:row-1+p_size(1), col:col-1+p_size(2),:); 
        return
    end
    
    % find mincut 
    patch =  texture(row:row-1+p_o_height, col:col-1+p_o_width,:); 
    if ovl_c > 1
        % vertical blending
        v_ovl_b = blend_patch_mincut(v_ovl, texture(row:row-1+p_o_height, col:col-1+ovl_c,:), 'v');
        patch(1:p_o_height,1:ovl_c,:) = v_ovl_b; 
    end
    if ovl_r > 1
        % horizontal blending
        h_ovl_b = blend_patch_mincut(h_ovl, texture(row:row-1+ovl_r, col:col-1+p_o_width,:), 'h'); 
        patch(1:ovl_r, 1:p_o_width,:) = h_ovl_b; 
    end
    if ovl_c > 1 && ovl_r > 1
        % corner blending  
        c_ovl_b = 0.5.*(v_ovl_b(1:ovl_r, 1:ovl_c,:) + h_ovl_b(1:ovl_r, 1:ovl_c,:)); 
        patch(1:ovl_r, 1:ovl_c,:)= c_ovl_b; 
    end
    
    
end 


function ssd = compute_ssd(patch1, patch2)
    % compute sum of squared difference 
    diff = (patch1-patch2).^2; 
    ssd = sum(diff(:)) / length(diff(:)); 
end

function blended = blend_patch_mincut(patch1, patch2, mode)
    if mode == 'h'
        patch1 = rot90(patch1,1); % counterclockwie 90 degree 
        patch2 = rot90(patch2,1); % counterclockwie 90 degree 
    end
    [nrows, ncols, ~] = size(patch1);
    E = sum((patch1-patch2).^2,3); % energy matrix (2D) 
    E_pad = padarray(E,[1,1], Inf, 'both'); % add padding 
    M = ones(nrows, ncols).*Inf; % scoring matrix   
    N = zeros(nrows, ncols); % min neighbour col 
    
    for r = 1:nrows
        for c = 1:ncols
            neighbours = [E_pad((r+1)-1,(c+1)-1), E_pad((r+1)-1,(c+1)), E_pad((r+1)-1,(c+1)+1)];
            [min_e, min_i] = min(neighbours); 
            M(r,c) = E(r,c) + min_e; 
            N(r,c) = c+(min_i-2); % at patch 
            N(r,c) = max(1,N(r,c)); 
            N(r,c) = min(ncols, N(r,c)); 
        end
    end
    % return the blended patch using mincut 
    blended = zeros(size(patch1));
    [~, c_blend] = min(M(nrows,:)); % init c_blend
    for r = nrows:-1:1
        blended(r,1:c_blend-1,:) = patch1(r,1:c_blend-1,:); 
        blended(r,c_blend:end,:) = patch2(r,c_blend:end,:); 
        c_blend = N(r,c_blend); % update c_blend from the table  
%         imshow(blended); 
    end
%     montage({patch1, blended, patch2}, 'Size', [1 3], 'BorderSize', 10);  
    if mode == 'h'
        blended = rot90(blended,3); % counterclockwie 270 degree 
    end
   
end 
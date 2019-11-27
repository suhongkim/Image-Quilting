function patch_ovl = blend_mincut(texture, t_loc, v_ovl, h_ovl)
    [p_o_height, ovl_c, ~] = size(v_ovl); % [(ovl_r + patch_r), ovl_c] 
    [ovl_r, p_o_width, ~]  = size(h_ovl); % [ovl_r, (ovl_c + patch_c)] 
    patch_ovl  =  texture(t_loc(1):t_loc(1)-1+p_o_height, t_loc(2):t_loc(2)-1+p_o_width,:); 
    % find mincut  
    if ovl_c > 1
        % vertical blending
        v_ovl_b = blend_patch_mincut(v_ovl, texture(t_loc(1):t_loc(1)-1+p_o_height, t_loc(2):t_loc(2)-1+ovl_c,:), 'v');
        patch_ovl(1:p_o_height,1:ovl_c,:) = v_ovl_b; 
    end
    if ovl_r > 1
        % horizontal blending
        h_ovl_b = blend_patch_mincut(h_ovl, texture(t_loc(1):t_loc(1)-1+ovl_r, t_loc(2):t_loc(2)-1+p_o_width,:), 'h'); 
        patch_ovl(1:ovl_r, 1:p_o_width,:) = h_ovl_b; 
    end
    if ovl_c > 1 && ovl_r > 1
        % corner blending  
        c_ovl_b = 0.5.*(v_ovl_b(1:ovl_r, 1:ovl_c,:) + h_ovl_b(1:ovl_r, 1:ovl_c,:)); 
        patch_ovl(1:ovl_r, 1:ovl_c,:)= c_ovl_b; 
    end
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
    end
%     montage({patch1, blended, patch2}, 'Size', [1 3], 'BorderSize', 10);  
    if mode == 'h'
        blended = rot90(blended,3); % counterclockwie 270 degree 
    end
   
end 
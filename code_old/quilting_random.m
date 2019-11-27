function quilted = quilting_random(texture, out_scale, patch_ratio)
    % read texture sample as double
    texture = im2double(texture);
    % define parameter size 
    txt_size = size(texture);
    out_size = [round(txt_size(1:2).*out_scale), txt_size(3)];
    pth_size = [round(txt_size(1:2).*patch_ratio), txt_size(3)]; 
    
    % quilt patches 
    quilted = zeros(out_size); 
    for r = 1 : pth_size(1) : out_size(1)
        r_end = min(out_size(1), r+pth_size(1)-1); 
        for c = 1: pth_size(2) : out_size(2)
            c_end = min(out_size(2), c+pth_size(2)-1); 
            % patch size based on output 
            p_r_end = min(pth_size(1), out_size(1)-r+1); 
            p_c_end = min(pth_size(2), out_size(2)-c+1);
            % sample patch randomly 
            patch = sample_patch_randomly(texture, [p_r_end, p_c_end]); 
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
 
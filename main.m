function [] = main()
%% Gradient Domain Fusion
% Part 1 is toy example, part 2 is poisson blending, part 3 is mixed
% blending
part = 3;
if part == 1 
    toyim = im2double(imread('./samples/toy_problem.png')); 
    % im_out should be approximately the same as toyim
    im_out = toy_reconstruct(toyim);
    disp(['Error: ' num2str(sqrt(sum(toyim(:)-im_out(:))))])
elseif part == 2
    im_background = imresize(im2double(imread('cloth.jpg')), 0.8, 'bilinear');
    im_object = imresize(im2double(imread('piedpiper.jpg')), 0.8, 'bilinear');

    % get source region mask from the user
    objmask = getMask(im_object);
    % align im_s and mask_s with im_background
    [im_s, mask_s] = alignSource(im_object, objmask, im_background);

    % blend
    im_blend = poissonBlend(im_s, mask_s, im_background);
    figure(3), hold off, imshow(im_blend)
    imwrite(im_blend, 'piperPoisson.jpg')
elseif part == 3
    im_background = imresize(im2double(imread('cloth.jpg')), 0.8, 'bilinear');
    im_object = imresize(im2double(imread('piedpiper2.jpg')), 0.8, 'bilinear');

    % get source region mask from the user
    objmask = getMask(im_object);
    % align im_s and mask_s with im_background
    [im_s, mask_s] = alignSource(im_object, objmask, im_background);

    % blend
    im_blend = mixedBlend(im_s, mask_s, im_background);
    figure(3), hold off, imshow(im_blend);
    imwrite(im_blend, 'piperMixed2.jpg');
end
end

%% Toy reconstruct helper functions
function [out] = toy_reconstruct(im)
[imh, imw] = size(im);
num = imh * imw;
A = sparse([], [], [], num * 2 + 1, num);
b = zeros(num * 2 + 1, 1);
e = 1;
for c = 1:imw - 1
    for r = 1:imh - 1
        var = (c - 1) * imh + r;
        A(e, var + 1) = 1;
        A(e, var) = -1;
        b(e) = im(r + 1, c) - im(r, c);
        e = e + 1;
        A(e, var + imh) = 1;
        A(e, var) = -1;
        b(e) = im(r, c + 1) - im(r, c);
        e = e + 1;
    end
end
for f = 1 : imh - 1
   var = (imw - 1) * imh + f;
   A(e, var + 1) = 1;
   A(e, var) = -1;
   b(e) = im(var + 1) - im(var);
   e = e + 1;
end
for d = 1 : imw - 1
    var = d * imh;
    A(e, var + imh) = 1;
    A(e, var) = -1;
    b(e) = im(var + imh) - im(var);
    e = e + 1;
end
A(e, 1) = 1;
b(e) = im(1, 1);
%v =  ((A' * A) ^ -1) * A' * b;
%v = lscov(A, b);
v = A \ b;
out = reshape(v, [imh, imw]);
imwrite(out, 'toyOut.png');
imshow(out);
end

%% Mixed blending helper
function [im_blend] = mixedBlend(im_s, mask_s, im_background)
r = mixedBlend_single(im_s(:, :, 1), mask_s, im_background(:, :, 1));
g = mixedBlend_single(im_s(:, :, 2), mask_s, im_background(:, :, 2));
b = mixedBlend_single(im_s(:, :, 3), mask_s, im_background(:, :, 3));
im_blend = cat(3, r, g, b);
end

function [im_blend] = mixedBlend_single(im_s, mask_s, im_background)
im_blend = im_background;
[r_ind, c_ind] = find(mask_s);
num = size(r_ind, 1);
A = sparse([], [], [], num * 4, num, num * 4 * 2);
b = zeros(num * 4, 1);
e = 1;
for a = 1 : num
    r = r_ind(a);
    c = c_ind(a);
    var = find(r_ind == r & c_ind == c, 1);
    
    
    r_comp = r + 1;
    c_comp = c;
    var_comp = find(r_ind == r_comp & c_ind == c_comp, 1);
    A(e, var) = 1;
    if abs(im_s(r, c) - im_s(r_comp, c_comp)) > abs(im_background(r, c) -...
            im_background(r_comp, c_comp))
        dij = im_s(r, c) - im_s(r_comp, c_comp);
    else
        dij = im_background(r, c) - im_background(r_comp, c_comp);
    end
    if mask_s(r_comp, c_comp) == 0
        b(e) = dij + im_background(r_comp, c_comp);
    else
        A(e, var_comp) = -1;
        b(e) = dij;
    end
    e = e + 1;
    
    r_comp = r;
    c_comp = c + 1;
    var_comp = find(r_ind == r_comp & c_ind == c_comp, 1);
    A(e, var) = 1;
    if abs(im_s(r, c) - im_s(r_comp, c_comp)) > abs(im_background(r, c) -...
            im_background(r_comp, c_comp))
        dij = im_s(r, c) - im_s(r_comp, c_comp);
    else
        dij = im_background(r, c) - im_background(r_comp, c_comp);
    end    
    if mask_s(r_comp, c_comp) == 0
        b(e) = dij + im_background(r_comp, c_comp);
    else
        A(e, var_comp) = -1;
        b(e) = dij;
    end
    e = e + 1;    
    
    r_comp = r - 1;
    c_comp = c;
    var_comp = find(r_ind == r_comp & c_ind == c_comp, 1);
    A(e, var) = 1;
    if abs(im_s(r, c) - im_s(r_comp, c_comp)) > abs(im_background(r, c) -...
            im_background(r_comp, c_comp))
        dij = im_s(r, c) - im_s(r_comp, c_comp);
    else
        dij = im_background(r, c) - im_background(r_comp, c_comp);
    end      
    if mask_s(r_comp, c_comp) == 0
        b(e) = dij + im_background(r_comp, c_comp);
    else
        A(e, var_comp) = -1;
        b(e) = dij;
    end
    e = e + 1;
    
    r_comp = r;
    c_comp = c - 1;
    var_comp = find(r_ind == r_comp & c_ind == c_comp, 1);
    A(e, var) = 1;
    if abs(im_s(r, c) - im_s(r_comp, c_comp)) > abs(im_background(r, c) -...
            im_background(r_comp, c_comp))
        dij = im_s(r, c) - im_s(r_comp, c_comp);
    else
        dij = im_background(r, c) - im_background(r_comp, c_comp);
    end      
    if mask_s(r_comp, c_comp) == 0
        b(e) = dij + im_background(r_comp, c_comp);
    else
        A(e, var_comp) = -1;
        b(e) = dij;
    end
    e = e + 1;
end
v = A \ b;
for d = 1 : num
   im_blend(r_ind(d), c_ind(d)) = v(d); 
end
end

%% Poisson blend help function
function [im_blend] = poissonBlend(im_s, mask_s, im_background)
r = poissonBlend_single(im_s(:, :, 1), mask_s, im_background(:, :, 1));
g = poissonBlend_single(im_s(:, :, 2), mask_s, im_background(:, :, 2));
b = poissonBlend_single(im_s(:, :, 3), mask_s, im_background(:, :, 3));
im_blend = cat(3, r, g, b);
end

function [im_blend] = poissonBlend_single(im_s, mask_s, im_background)
im_blend = im_background;
[r_ind, c_ind] = find(mask_s);
num = size(r_ind, 1);
A = sparse([], [], [], num * 4, num, num * 4 * 2);
b = zeros(num * 4, 1);
e = 1;
for a = 1 : num
    r = r_ind(a);
    c = c_ind(a);
    var = find(r_ind == r & c_ind == c, 1);
    
    
    r_comp = r + 1;
    c_comp = c;
    var_comp = find(r_ind == r_comp & c_ind == c_comp, 1);
    A(e, var) = 1;
    if mask_s(r_comp, c_comp) == 0
        b(e) = im_s(r, c) - im_s(r_comp, c_comp) + im_background(r_comp, c_comp);
    else
        A(e, var_comp) = -1;
        b(e) = im_s(r, c) - im_s(r_comp, c_comp);
    end
    e = e + 1;
    
    r_comp = r;
    c_comp = c + 1;
    var_comp = find(r_ind == r_comp & c_ind == c_comp, 1);
    A(e, var) = 1;
    if mask_s(r_comp, c_comp) == 0
        b(e) = im_s(r, c) - im_s(r_comp, c_comp) + im_background(r_comp, c_comp);
    else
        A(e, var_comp) = -1;
        b(e) = im_s(r, c) - im_s(r_comp, c_comp);
    end
    e = e + 1;    
    
    r_comp = r - 1;
    c_comp = c;
    var_comp = find(r_ind == r_comp & c_ind == c_comp, 1);
    A(e, var) = 1;
    if mask_s(r_comp, c_comp) == 0
        b(e) = im_s(r, c) - im_s(r_comp, c_comp) + im_background(r_comp, c_comp);
    else
        A(e, var_comp) = -1;
        b(e) = im_s(r, c) - im_s(r_comp, c_comp);
    end
    e = e + 1;
    
    r_comp = r;
    c_comp = c - 1;
    var_comp = find(r_ind == r_comp & c_ind == c_comp, 1);
    A(e, var) = 1;
    if mask_s(r_comp, c_comp) == 0
        b(e) = im_s(r, c) - im_s(r_comp, c_comp) + im_background(r_comp, c_comp);
    else
        A(e, var_comp) = -1;
        b(e) = im_s(r, c) - im_s(r_comp, c_comp);
    end
    e = e + 1;
end
v = A \ b;
for d = 1 : num
   im_blend(r_ind(d), c_ind(d)) = v(d); 
end
end

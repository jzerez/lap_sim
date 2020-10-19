%%
%requires image resolution of 150ppi. Track should be scaled to 1in = 200ft in image. Plots will have a scale ratio of 0.4 m per unit.  
%%
clear all
close all
track = ~imbinarize(rgb2gray(imread("MichiganTrack2019.jpg")), 0.5);
scale = 0.4;

start_x = size(track,2)/2;              % define starting x-coordinate for boundary trace
start_y = find(track(:,start_x), 1);    % define starting y-coordinate for boundary trace
start = [start_y,start_x];              % starting coordinate

boundary = bwtraceboundary(track,start,'N')';       %trace of bw image along boundary 
%%
close all
reduced = boundary(:, 1:2:end);

points = zeros(size(reduced));
points(1, :) = reduced(2, :)*scale;
points(2, :) = -reduced(1, :).*scale;

figure
plot(points(1, :),points(2, :)) %plot track
diff_points = diff([points(:, end), points], 1, 2);
rs = zeros([1, length(points)]);
ds = zeros(size(rs));
angles = zeros(size(rs));

mean_size = 20;

num_pts = length(diff_points);

for i = 1:num_pts
    last_ind = mod(i-mean_size/2, num_pts)+1;
    first_ind = mod(i+mean_size/2, num_pts)+1;
   
    v1 = unit(diff_points(:, last_ind));
    v2 = unit(diff_points(:, first_ind));
    
    p1 = points(:, last_ind);
    p2 = points(:, first_ind);
   
    angle = acos(dot(v1, v2));
    d = norm(p1-p2);

    angles(i) = real(angle);
    ds(i) = d;
    rs(i) = (real(angle) / d);
end

zz = zeros([2, length(points)]);
figure
hold on
h = surf([points(1,:); points(1,:)], [points(2,:); points(2,:)],zz,[rs; rs],'EdgeColor','interp');
set(h, 'LineWidth', 2.5)
% plot(apex(:,1),apex(:,2),'bd')
%plot(center(:,1),center(:,2),'ro')
%quiver(diff_points(2:end-1,1),diff_points(2:end-1,2),radius_vector(:,1),radius_vector(:,2),'g-')
colormap jet
colorbar
% caxis([0 75])
hold off
disp(1/max(rs) + 2.25)
%%
function center = calc_circle(p1, p2, p3)
    mid1 = (p2+p1) / 2;
    mid2 = (p3+p2) / 2;
    slope1 = -(p2(1) - p1(1)) / (p2(2)-p1(2));
    slope2 = -(p3(1) - p2(1)) / (p3(2)-p2(2));
    system = rref([1, -slope1, mid1(2) - (slope1 * mid1(1));
              1, -slope2, mid2(2) - (slope2 * mid2(1))]);
    center = [system(2, 3), system(1,3)];
end

function res = unit(v)
    res = v / norm(v);
end
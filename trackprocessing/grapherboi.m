%%
%requires image resolution of 150ppi. Track should be scaled to 1in = 200ft in image. Plots will have a scale ratio of 0.4 m per unit.  
%%
clear all
%close all
manual_apex = xlsread('apex.xlsx')*.4;
track = ~imbinarize(rgb2gray(imread("MichiganTrack2019.jpg")), 0.5);
 
scale = 0.4;

start_x = size(track,2)/2;              % define starting x-coordinate for boundary trace
start_y = find(track(:,start_x), 1);    % define starting y-coordinate for boundary trace
start = [start_y,start_x];              % starting coordinate

boundary = bwtraceboundary(track,start,'N')';       %trace of bw image along boundary 
%%
close all
reduced = boundary(:,1:4:end);          

points = zeros(size(reduced));
points(1, :) = reduced(2, :)*scale;
points(2, :) = (-reduced(1, :)+670).*scale;

figure
plot(points(1, :),points(2, :)) %plot track
diff_points = diff([points(:, end), points], 1, 2);
rs = zeros([1, length(points)]);
ds = zeros(size(rs));
angles = zeros(size(rs));

mean_size = 6;

num_pts = length(diff_points);

for i = 1:num_pts
    shifted = circshift(diff_points,i+(mean_size/2)-1,2);
    
    v1 = unit(shifted(:, 1));
    v2 = unit(shifted(:, mean_size+1));
    
    vs = vecnorm(shifted(:, 1:mean_size+1));
    
    angle = acos(dot(v1, v2));
    d = sum(vs);

    angles(i) = real(angle);
    ds(i) = d;
    rs(i) = (real(angle) / d);
end

rs = fliplr(rs);
turns = rs(1,:)>=0.04; %labels points as being part of a turn (1) or a straight (0)

i = 1;
j = 1;
while i<size(rs,2)-1
    init = i
    while turns(i)-turns(i+1)==0
        i = i+1;
        if i == size(rs,2)-1
            break
        end
    end
    if turns(init) == 1
        [curve, index] = max(rs(:,init:i));
        apex(j) = init+index-1; 
        j = j+1;
    end
    i = i+1;
end
%apex = points(:,islocalmax(rs));

zz = zeros([2, length(points)]);
figure
hold on
h = surf([points(1,:); points(1,:)], [points(2,:); points(2,:)],zz,[rs; rs],'EdgeColor','interp');
set(h, 'LineWidth', 2.5)
plot(points(1,turns),points(2,turns),'ro')
plot(points(1,apex),points(2,apex),'bd')
%plot(apex(1,:),apex(2,:),'bd')
%plot(center(:,1),center(:,2),'ro')
%quiver(diff_points(2:end-1,1),diff_points(2:end-1,2),radius_vector(:,1),radius_vector(:,2),'g-')
colormap jet
colorbar
% caxis([0 75])
%plot(points(1,apex),points(2,apex),'ro')
%scatter(manual_apex(:,1),manual_apex(:,2),[],'g','filled','s')
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
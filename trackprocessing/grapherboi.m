%%
% requires image resolution of 150ppi. Track should be scaled to 1in = 200ft in image. Plots will have a scale ratio of 0.4 m per unit.  
%%
clear all
manual_apex = xlsread('apex.xlsx')*.4;
track = ~imbinarize(rgb2gray(imread('MichiganTrack2019.jpg')), 0.5);
 
scale = 0.4;                            % scale of 1 pixel = 0.4 meters

start_x = size(track,2)/2;              % define starting x-coordinate for boundary trace
start_y = find(track(:,start_x), 1);    % define starting y-coordinate for boundary trace
start = [start_y,start_x];              % starting coordinate

boundary = bwtraceboundary(track,start,'N')';       %trace of bw image along boundary 
%%
close all
reduced = boundary(:,1:4:end);          % reduce granularity of track by only using every 4th pixel

points = zeros(size(reduced));          % create empty matrix
points(1, :) = reduced(2, :)*scale;     % convert pixel positions to meters and move x-coordinates to first row
points(2, :) = (-reduced(1, :)+670).*scale;     % convert pixel positions to meters and move y-coordinates to second row

figure
plot(points(1, :),points(2, :))         %plot track
diff_points = diff([points(:, end), points], 1, 2);     % calculate the relative location of points
rs = zeros([1, length(points)]);        % create empty matrix to hold curvature values
ds = zeros(size(rs));                   % create empty matrix to hold arc length values
angles = zeros(size(rs));               % create empty matrix to hold delta angle values

mean_size = 6;                          % number of points in the arc

num_pts = length(diff_points);          % total number of points that make up the track

for i = 1:num_pts
    shifted = circshift(diff_points,i+(mean_size/2)-1,2);   % shift array so arc is first (mean_size) elements
    
    v1 = unit(shifted(:, 1));       % unit vector representing the track direction at the first point 
    v2 = unit(shifted(:, mean_size+1)); % unit vector representing the track direction at the last point
    
    vs = vecnorm(shifted(:, 1:mean_size+1));    % calculate the distance between points
    
    angle = acos(dot(v1, v2));      % calculate the change in angle along the arc
    d = sum(vs);                    % calculate arc length

    angles(i) = real(angle);        % store angle value
    ds(i) = d;                      % store arc length
    rs(i) = (real(angle) / d);      % store curvature value (at the midpoint of the arc)
end

rs = fliplr(rs);        % flip array to match points
turns = rs(1,:)>=0.04;  %labels points as being part of a turn (1) or a straight (0)

% Calculate turn apexes by finding global maximum of curvature along a
% continuous turn

i = 1;
j = 1;
while i<size(rs,2)-1
    init = i;
    while turns(i)-turns(i+1)==0        % find continuous turns/straights
        i = i+1;
        if i == size(rs,2)-1
            break
        end
    end
    if turns(init) == 1     % if not a straight
        [curve, index] = max(rs(:,init:i));     % find global max
        apex(j) = init+index-1;             % save global index
        j = j+1;
    end
    i = i+1;
end

zz = zeros([2, length(points)]);
figure
hold on
h = surf([points(1,:); points(1,:)], [points(2,:); points(2,:)],zz,[rs; rs],'EdgeColor','interp');
set(h, 'LineWidth', 2.5)
%scatter3(manual_apex(:,1),manual_apex(:,2),zeros(size(manual_apex,1),1),'g', 'filled','o','MarkerSize', 2)
plot(manual_apex(:,1),manual_apex(:,2),'g*','MarkerSize',7)
plot(points(1,apex),points(2,apex),'bd')
colormap jet
colorbar
% caxis([0 75])
%plot(points(1,apex),points(2,apex),'ro')
%scatter(manual_apex(:,1),manual_apex(:,2),[],'g','filled','s')
hold off
%disp(1/max(rs) + 2.25)
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
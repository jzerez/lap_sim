%%
%requires image resolution of 150ppi. Track should be scaled to 1in = 200ft in image. Plots will have a scale ratio of 0.4 m per unit.  
%%
clear all
close all
manual_apex = xlsread('apex.xlsx')*.4;
color = imread("MichiganTrack2019.jpg");
grey = rgb2gray(color);
bw = grey<=125;
scale = 0.4;

start_x = size(bw,2)/2-50;              %define starting x-coordinate for boundary trace
start_y = min(find(bw(:,start_x)));     %define starting y-coordinate for boundary trace
start = [start_y,start_x];              %starting coordinate

boundary = bwtraceboundary(bw,start,'N');       %trace of bw image along boundary 
%scale = 1/(max(boundary(:,2))/(10.8667*60.96));
reduced = boundary(1:2:end,:);

points = zeros(size(reduced));
points(:,1) = reduced(:,2)*scale;
points(:,2) = (reduced(:,1)*-1+670).*scale;

figure
hold on
plot(points(:,1),points(:,2)) %plot track
plot(manual_apex(:,1),manual_apex(:,2),'rs')
hold off

diff_points = [points(end,:); points];
points = points(1:end-1,:);             %remove repeat

for i = 1:size(diff_points,1)-2
    center(i,:)= calc_circle(diff_points(i,:),diff_points(i+1,:),diff_points(i+2,:));
    radius_vector(i,:) = center(i,:)-diff_points(i+1,:);
    radius(i) = norm(center(i,:)-diff_points(i+1,:));
end

% figure
% hold on
% plot(center(:,1),center(:,2),'ro')
% 
% hold off
% hold ons
% ind = better_radius <= 100;
% plot(points(ind,1),points(ind,2),'ro')
% hold off

index_sums = (islocalmin(radius,'MinSeparation',5))+(radius<=25);
apex_index = index_sums == 2;
apex = diff_points(apex_index,:);
zz = zeros(size(points,1),2);
figure
hold on
surf([points(:,1) points(:,1)],[points(:,2) points(:,2)],zz,[radius' radius'],'EdgeColor','interp');
plot(manual_apex(:,1),manual_apex(:,2),'rs')
plot(apex(:,1),apex(:,2),'bd')
%plot(center(:,1),center(:,2),'ro')
%quiver(diff_points(2:end-1,1),diff_points(2:end-1,2),radius_vector(:,1),radius_vector(:,2),'g-')
colormap parula
colorbar
caxis([0 75])
xlim([0 700])
ylim([0 300])
hold off
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

clear all
close all
color = imread("MichiganTrack2019.jpg");
grey = rgb2gray(color);
bw = grey<=125;
figure
imshow(bw)

start_x = size(bw,2)/2-50;
start_y = min(find(bw(:,start_x)));
start = [start_y,start_x];

figure
boundary = bwtraceboundary(bw,start,'N');
imshow(bw)
hold on;
plot(start_x,start_y,'rs')
plot(boundary(:,2),boundary(:,1),'g','LineWidth',1);
hold off
% 
% points = track<=150;
% figure
% imshow(points)
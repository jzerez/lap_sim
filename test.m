clear all
close all
addpath classes
a = Dummy(150);
aero = Aero(3, 1.5, -2.5, 0, 1);
load('./assets/motors/emrax228_continuous_torque_vs_rpm_curve.mat')
transmission = Transmission(70, 3.75, curve);
tire = './assets/tires/Hoosier_18x6_10_7in_14psi_V43.tir';
tire_r = 0.2;
c = Car(a, transmission, aero, tire, tire_r);
% c.mass

% cone = c.calc_cone(tire, [5:5:35], 20, 25);
% c.calc_min_r(cone)
% c.calc_min_vel(9)
% 
% comps = ["./assets/competition_info/formula_north_2019.mat";
%          "./assets/competition_info/formula_electric_2018.mat"];
% sc = ScoreCalculator(comps);

%test track
track_img ='assets/track/MichiganTrack2019.jpg';
apex_pts = 'assets/track/apex.xlsx';
t = Track(track_img,apex_pts);
%t.plot
t.get_points(0);

s = Simulator(c,t);

%%
%s.calc_leg

[points, radii] = s.track.get_points(s.pos);  % retrieve points in current lap section (current apex to next apex)

apex1_r = radii(1);         % radius of the turn at the first apex
apex2_r = radii(end);       % radius of the turn at the second apex

n_points = size(points, 2); % number of points in the lap section

vels = zeros([1, n_points]);
forward_vels = vels;
reverse_vels = vels;
accels = zeros([1, n_points]);
forward_accels = accels;
reverse_accels = accels; 

forward_vels(1) = s.calc_max_vel(apex1_r);    % calculate the maximum possible velocity at the first apex
reverse_vels(1) = s.calc_max_vel(apex2_r);    % calculate the maximum possible velocity at the second apex

dist = vecnorm(diff(points, 1, 2));  % calculates the distances between points in the leg

% forward acceleration integration
for i = 1:size(dist,2)
    [forward_fx,forward_fy] = s.interp_force(s.car.friction_cone, forward_vels(i), radii(i), 1);    % forces at first apex
    forward_accels(i) = forward_fx/s.car.mass
    if forward_accels(i) < 0
        disp('neg accel')
        forward_accels(i:size(dist,2)) = 0;
        forward_vels(i+1:size(dist,2)+1) = forward_vels(i);
        break
    end
    time = max(roots([forward_accels(i)/2 forward_vels(i) -dist(i)]));
    forward_vels(i+1) = forward_vels(i)+forward_accels(i)*time;
end 

figure
plot([0 cumsum(dist)],forward_vels)
xlabel('Distance (m)')
ylabel('Velocity (m/s)')
title('Forward Integrated Velocity from the Entry Apex')

%%
% reverse acceleration integration
for j = 1:size(dist,2)
    [reverse_fx,reverse_fy] = s.interp_force(s.car.friction_cone, reverse_vels(j), radii(end+1-j), -1);   % forces at second apex
    reverse_accels(j) = reverse_fx/s.car.mass;
    if reverse_accels(j) > 0
        disp('pos accel')
        reverse_accels(j:size(dist,2)) = 0;
        reverse_vels(j+1:size(dist,2)+1) = reverse_vels(j);
        break
    end
    time = max(roots([reverse_accels(j)/2 reverse_vels(j) -dist(end+1-j)]));
    reverse_vels(j+1) = reverse_vels(j)+reverse_accels(j)*time;
end

integrated_vels = [forward_vels; fliplr(reverse_vels)];
integrated_accels = [forward_accels; fliplr(reverse_accels)];

vels = min(integrated_vels);
accels = min(integrated_accels);

figure
hold on
plot(forward_vels,'ro-')
plot(fliplr(reverse_vels),'bs-')
xlabel('Point in Leg')
ylabel('Velocity')
legend('Forwards Integration', 'Reverse Integration')
hold off

%%
% fys = [1.2372 1.2287];
% fxs = [-0.3315 -0.1618];
% 
% interp1(fys,fxs,1.0715)
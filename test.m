close all
addpath classes
a = Dummy(110);
aero = Aero(3, 1.5, -2.5, 0, 1);
tire = './assets/tires/Hoosier_18x6_10_7in_14psi_V43.tir';
c = Car(a, a, aero, tire);
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
t.plot
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
    forward_accels(i) = forward_fx/s.car.mass;
    time = max(roots([forward_accels(i)/2 forward_vels(i) -dist(i)]));
    forward_vels(i+1) = forward_vels(i)+forward_accels(i)*time;
end 


%%
% reverse acceleration integration
for j = 1:size(dist,2)
    [reverse_fx,reverse_fy] = s.interp_force(s.car.friction_cone, reverse_vels(i), radii(end+1-i), -1);   % forces at second apex
    reverse_accels(i) = reverse_fx/s.car.mass;
    time = max(roots([reverse_accels(i)/2 reverse_vels(i) -dist(end+1-i)]));
    reverse_vels(i+1) = reverse_vels(i)+reverse_accels(i)*time;
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
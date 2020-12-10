clear all
close all
addpath classes
a = Dummy(150);
aero = Aero(3, 0.9, -2.5, 0, 1.25);
load('./assets/motors/emrax228_continuous_torque_vs_rpm_curve.mat')
tire_r = 0.225;
transmission = Transmission(70, 3.75, curve, tire_r);
tire = './assets/tires/Hoosier_18x6_10_7in_14psi_V43.tir';

c = Car(a, transmission, aero, tire, tire_r);
c.mass = 285;
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
t = Track(track_img);
t.plot
t.get_points(1);
% t.plot()

s = Simulator(c,t);
s.run_simulation
s.plot_velocity


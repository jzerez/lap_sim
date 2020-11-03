close all
addpath classes
a = Dummy(110);
aero = Aero(3, 1.5, -2.5, 0, 1);
c = Car(a, a, a, aero);
c.mass

% tire = './assets/tires/Hoosier_18x6_10_7in_14psi_V43.tir';
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
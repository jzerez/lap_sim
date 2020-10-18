addpath classes
a = Dummy(110);
aero = Aero(3, 1.33, -2.5, 0, 1);
c = Car(a, a, a, aero);
c.mass

% tire = './assets/tires/Hoosier_18x6_10_7in_14psi_V43.tir';
% c.calc_cone(tire, [10,20, 30, 40], 20, 25);

comps = ["./assets/competition_info/formula_north_2019.mat";
         "./assets/competition_info/formula_electric_2018.mat"];
sc = ScoreCalculator(comps);
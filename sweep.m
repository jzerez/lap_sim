clear all
close all
addpath classes

masses = linspace(250, 325, 25);
energies = zeros(size(masses));
times = zeros(size(masses));
for i = 1:length(masses)
    mass = masses(i);
    [time, energy] = sim(mass);
    times(i) = time;
    energies(i) = energy;
    
end
close all
figure
plot(masses, times)
hold on
plot(masses, energies)

function [time, energy] = sim(mass)
    a = Dummy(150);
    aero = Aero(3, 0.9, -2.5, 0, 1.25);
    load('./assets/motors/emrax228_continuous_power_vs_rpm_curve.mat')
    power_curve = curve;

    load('./assets/motors/emrax228_continuous_torque_vs_rpm_curve.mat')
    tire_r = 0.225;
    transmission = Transmission(70, 3.75, curve, tire_r, power_curve);
    tire = './assets/tires/Hoosier_18x6_10_7in_14psi_V43.tir';

    c = Car(a, transmission, aero, tire, tire_r);
    c.mass = mass;

    %test track
    track_img ='assets/track/MichiganTrack2019.jpg';

    t = Track(track_img);
    t.plot;
    % t.get_points(1);
    % t.plot()

    s = Simulator(c,t);
    s.run_simulation
    time = s.time;
    energy = s.energy_used;
end
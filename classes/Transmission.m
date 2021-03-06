classdef Transmission < handle
    properties
        mass;               % kg
        gear_ratio;         % unitless (driver/driven)
        torque_vs_rpm;      % torque vs. rpm function [rpm; torque (Nm)]
    end
    
    methods
        function self = Transmission(mass, gear_ratio, torque_vs_rpm)
            self.mass = mass;
            self.gear_ratio = gear_ratio;
            self.torque_vs_rpm = torque_vs_rpm;
        end
        
        function res = motor_curve_228(self)
            % The motor curve for an emrax 228
            % Assumes continuous force
            rpms = [0, 1400, 4000, 5000];
            torques = [96, 120,120,108];
            res = [rpms; torques];
        end
        
        function res = motor_curve_208(self)
            % The motor curve for an emrax 208
            % Assumes continuous force
            rpms = [0, 1600, 3000, 6000];
            torques = [72.5, 80, 80, 65];
            curve = [rpms; torques];
        end
    end

end
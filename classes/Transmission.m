classdef Transmission < handle
    properties
        mass;               % kg
        gear_ratio;         % unitless (driver/driven)
        motor_curve;        % torque vs. rpm function
    end
    
    methods
        function self = Transmission(mass, gear_ratio, motor_curve)
            self.mass = mass;
            self.gear_ratio = gear_ratio;
            self.motor_curve = motor_curve;
        end
    end

end
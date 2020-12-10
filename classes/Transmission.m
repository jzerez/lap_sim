classdef Transmission < handle
    properties
        mass;               % kg
        gear_ratio;         % unitless (driver/driven)
        torque_vs_rpm;      % torque vs. rpm function [rpm; torque (Nm)]
        max_vel;            % maximum vehicle velocity that the tranmission can support (m/s)
        r;                  % tire radius (m)
        power_vs_rpm;       % power vs. rpm function [rpms; power (kW)]
    end
    
    methods
        function self = Transmission(mass, gear_ratio, torque_vs_rpm, r, power_vs_rpm)
            self.mass = mass;
            self.gear_ratio = gear_ratio;
            self.torque_vs_rpm = torque_vs_rpm;
            self.power_vs_rpm = power_vs_rpm;
            self.r = r;
            self.max_vel = max(torque_vs_rpm(1, :)) / 60 * (2* pi) * r / gear_ratio;
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
        
        function max_force = calc_max_force(self, vel)
                % calculate corresponding motor rpm given gear ratio
                motor_rpm = vel / self.r / (2 * pi) * 60 * self.gear_ratio;
                curve = self.torque_vs_rpm;
                if motor_rpm > max(curve(1, :))
                    motor_rpm = max(curve(1, :));
                end
                
                % interpolate max motor torque for given rpm
                motor_torque_lim = interp1(curve(1, :), curve(2, :), motor_rpm);
                % Divide by two because max force for each rear wheel is
                % half of total
                max_force = motor_torque_lim * self.gear_ratio / self.r / 2; 
        end
        
        function power = calc_power(self, vel)
            motor_rpm = vel / self.r / (2 * pi) * 60 * self.gear_ratio;
            curve = self.torque_vs_rpm;
            if motor_rpm > max(curve(1, :))
                motor_rpm = max(curve(1, :));
            end
            
            % interpolate max motor torque for given rpm
            power = interp1(curve(1, :), curve(2, :), motor_rpm);
        end
        
    end

end
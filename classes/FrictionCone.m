classdef FrictionCone
    properties
        % Friction cone based on tires.
        % Lateral Longitudinal Velocity axes
        cone;       
        tire;
    end
    
    methods
        function self = FrictionCone(tire)
            self.tire = tire;
        end
        
        function self = calc_cone(aero)
            % Calculate the cone based on TTC and aero
        end
    end
end
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
        
        
        function self = import_cone(cone)
            self.cone = cone;
        end
    end
end
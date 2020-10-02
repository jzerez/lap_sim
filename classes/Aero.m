classdef Aero
    properties
        mass;           % kg
        coef_drag;      % unitless
        coef_lift;      % unitless
        drs;            % Bool (True if open, False if closed)
    end
    
    methods
        function self = Aero(mass, coef_drag, coef_lift, drs)
            self.mass = mass;
            self.coef_drag = coef_drag;
            self.coef_lift = coef_lift;
            self.drs = drs;
        end
    end
end
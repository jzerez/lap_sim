classdef Aero
    properties
        mass;           % kg
        coef_drag;      % unitless
        coef_lift;      % unitless
        drs;            % Bool (True if open, False if closed)
        area;           % m^2 (frontal area of aero)
        rho = 1.225;    % kg / m^3
    end
    
    methods
        function self = Aero(mass, coef_drag, coef_lift, drs, area)
            self.mass = mass;
            self.coef_drag = coef_drag;
            self.coef_lift = coef_lift;
            self.drs = drs;
            self.area = area;
        end
        
        function drag = calc_drag(self, vel)
            % Calculates the drag force in Newtons for a given velocity
            drag = -self.coef_drag * self.rho * vel^2 * self.area * 0.5;
        end
        
        function lift = calc_lift(self, vel)
            % Calculates the lift force in Newtons for a given velocity
            % Negative means downforce!
            lift = self.coef_lift * self.rho * vel^2 * self.area * 0.5;
        end
    end
end
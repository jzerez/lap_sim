classdef Car < handle
    properties
        mass;
        accumulator;
        transmission;
        frction_cone;
        aero;
    end
    
    methods
        function self = Car(accumulator, transmission, frction_cone, aero)
            self.accumulator = accumulator;
            self.transmission = transmission;
            self.frction_cone = frction_cone;
            self.aero = aero;
            self.mass = self.calc_mass();
        end
        
        function mass = calc_mass(self)
            mass = self.accumulator.mass + self.transmission.mass + self.aero.mass;
        end
    end
end
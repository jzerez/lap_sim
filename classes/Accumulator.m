classdef Accumulator < handle
    properties
        mass;                       % kg
        max_capacity;               % Wh
        peak_power;                 % W
        state_of_charge;            % Wh
        temp;                       % C
    end
    
    methods
        function self = Accumulator(mass, max_capacity, peak_power)
            self.mass = mass;
            self.max_capacity = max_capacity;
            self.peak_power = peak_power;
            self.state_of_charge = state_of_charge;
            self.state_of_charge = max_capacity;
            self.temp = 25;
        end
        
    end
    
end
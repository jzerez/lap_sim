classdef Dummy
    properties
        mass;
        num_points = 100;
    end
    
    methods
        function self = Dummy(mass)
            self.mass = mass;
        end
    end
end
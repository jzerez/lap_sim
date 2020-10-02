classdef Simulator
    properties
        car;            % Car object
        track;          % Track object
        postion = 0;    % Representing the apex number (integer)
        time = 0;       % Laptime (s)
    end
    
    methods
        function self = Simulator(car, track)
            self.car = car;
            self.track = track;
        end
        
        function self = calc_leg()
            % Calculates the time between the current apex and the next
            % apex. Also updates current position 
        end
    end
end
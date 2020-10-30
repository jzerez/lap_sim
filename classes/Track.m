classdef Track
    properties
        % track points 
        num_points;
    end
    
    methods
        % write plot function to plot track based off endpoints and apex
        % points
        
        function [points, radii] = get_points(self, apex_index)
            % returns the x,y coordinates for the track points between the
            % current apex_index and the next apex index. 
        end
    end
    
end
classdef Track
    properties
        num_points; % number of track points
        points;     % track points
        curvature;  % curvature of the track at each point
        apex;       % indices of apex points
    end
    
    methods
        function self = Track(track_img,apex_points)
            % Processes track image to create list of points that define
            %   the track, the curvature of the track at each point and the
            %   location of the turn apexes.
            %
            % Parameters: 
            %   track_img: an image of the track to be used, scale must be
            %       specified in scale variable
            %   apex_points (optional): a .csv file containing the positions of the
            %       apexes found manually
            % 
            % Returns: 
            %   self.num_points: double value representing the number of
            %       track points
            %   self.points: 2D array that contains the list of points
            %   	that define the track (each column is a new point, row
            %   	1 is the x-coordinate, row 2 is the y-coordinate)
            %   self.curvature: the curvature at each point along the track
            %   self.apex: list of indexes of points that are at turn
            %       apexes
            
            trace = ~imbinarize(rgb2gray(imread(track_img)), 0.5);
            scale = 0.4;                            % meters per pixel
            start_x = size(trace,2)/2;              % define starting x-coordinate for boundary trace
            start_y = find(trace(:,start_x), 1);    % define starting y-coordinate for boundary trace
            start = [start_y,start_x];              % starting coordinate
            
            boundary = bwtraceboundary(trace, start, 'N')'; % coordinates of each track pixel, x's on the first row, y's on the second
            reduced = boundary(:, 1:2:end);         % reduce granularity of points
            
            points = zeros(size(reduced));          % create empty matrix
            points(1, :) = reduced(2, :)*scale;     % convert pixel positions to meters and move x-coordinates to first row
            points(2, :) = (-reduced(1, :)+670).*scale;     % convert pixel positions to meters and move y-coordinates to second row
            self.points = points;
            self.num_points = size(points,2);
            
            diff_points = diff([points(:, end), points], 1, 2);     % calculate the relative location of points
            rs = zeros([1, length(points)]);        % create empty matrix to hold curvature values
            ds = zeros(size(rs));                   % create empty matrix to hold arc length values
            angles = zeros(size(rs));               % create empty matrix to hold delta angle values

            mean_size = 10;                          % number of points in the arc

            num_pts = length(diff_points);          % total number of points that make up the track

            for i = 1:num_pts
                shifted = circshift(diff_points,i+(mean_size/2)-1,2);   % shift array so arc is first (mean_size) elements

                v1 = shifted(:, 1)/norm(shifted(:, 1));       % unit vector representing the track direction at the first point 
                v2 = shifted(:, mean_size+1)/norm(shifted(:, mean_size+1)); % unit vector representing the track direction at the last point

                vs = vecnorm(shifted(:, 1:mean_size+1));    % calculate the distance between points

                angle = acos(dot(v1, v2));      % calculate the change in angle along the arc
                d = sum(vs);                    % calculate arc length

                angles(i) = real(angle);        % store angle value
                ds(i) = d;                      % store arc length
                rs(i) = (real(angle) / d);      % store curvature value (at the midpoint of the arc)
            end
            curvature = fliplr(rs);        % flip array to match points
            self.curvature = curvature; 
                
            if exist('apex_points','var')   %using manually located apexes
                disp("Manual")
                manual_apex = xlsread(apex_points)'.*scale;
                for i = 1:size(manual_apex,2)
                    [min_val, min_indx] = min(sum((points-manual_apex(:,i)).^2,1));
                    apex(i) = min_indx;
                end
                
            else                            % computationally find apexes
               disp("Computational")
               turns = curvature(1,:)>=0.04;  %labels points as being part of a turn (1) or a straight (0)
%                apex = []
               i = 1;
               j = 1;
               while i<size(curvature,2)-1
                   init = i;
                   while turns(i)-turns(i+1)==0        % find continuous turns/straights
                       i = i+1;
                       if i == size(curvature,2)-1
                           break
                       end
                   end
                   if turns(init) == 1     % if not a straight
                       [curve, index] = max(curvature(:,init:i));     % find global max
                       apex(j) = init+index-1;             % save global index
                       j = j+1;
                   end
                   i = i+1;
               end
            end
            self.apex = apex;    
        end
        
        function plot(self)
            % Plot function to plot a visualization of the track and the
            %   turn apexes
            
            zz = zeros([2, self.num_points]);
            figure
            hold on
            h = surf([self.points(1,:); self.points(1,:)], [self.points(2,:); self.points(2,:)],zz,[self.curvature; self.curvature],'EdgeColor','interp');
            set(h, 'LineWidth', 2.5)
            plot(self.points(1,self.apex),self.points(2,self.apex),'bd')
            colormap jet
            colorbar
            hold off
        end
        
        function [points, radii] = get_points(self, apex_index)
            % returns the x,y coordinates for the track points between the
            %   current apex_index and the next apex index. 
            init = self.apex(apex_index+1);
            final = self.apex(apex_index+2);
            points = self.points(:,init:final);
            radii = 1./self.curvature(init:final);
        end
    end
    
end
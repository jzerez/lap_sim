classdef Simulator < handle
    properties
        car;            % Car object
        track;          % Track object
        pos = 0;        % Representing the apex number (integer)
        time = 0;       % Total Laptime (s)
        vels;           % Maximum possible velocity at each track point
        accels;         % Maximum possible acceleration at each track point
        last_point_ind = 0;     
        min_rs;         % list of minimum radii for range of velocities
        t_step = 0.01;  % timestep (s)
    end
    
    methods
        function self = Simulator(car, track)
            self.car = car;
            self.track = track;
            
            self.calc_min_rs(self.car.friction_cone);
            self.vels = zeros([1, self.track.num_points]);
            self.accels = zeros([1, self.track.num_points]);
        end
        
        function self = calc_min_rs(self, cone)
            % Calculates minimum radius the car is capable of navigating
            % over a range of velocities. 
            
            vs = squeeze(cone(3,1,:))';
            max_fys = zeros(size(vs));
            
            for index = 1:length(vs)
                max_fys(index) = max(cone(1,:,index));
            end
            rs = vs.^2 * self.car.mass ./ max_fys;
            res = [rs; vs];
            self.min_rs = [rs; vs];
        end
        
        function self = calc_leg(self)
            % Calculates the time between the current apex and the next
            % apex, updates simulation laptime and car position. 
            [points, radii] = self.track.get_points(self.pos);  % retrieve points in current lap section (current apex to next apex)

            apex1_r = radii(1);         % radius of the turn at the first apex
            apex2_r = radii(end);       % radius of the turn at the second apex

            n_points = size(points, 2); % number of points in the lap section

            vels = zeros([1, n_points]);
            forward_vels = vels;
            reverse_vels = vels;
            accels = zeros([1, n_points]);
            forward_accels = accels;
            reverse_accels = accels; 

            forward_vels(1) = self.calc_max_vel(apex1_r);    % calculate the maximum possible velocity at the first apex
            reverse_vels(1) = self.calc_max_vel(apex2_r);    % calculate the maximum possible velocity at the second apex

            dist = vecnorm(diff(points, 1, 2));  % calculates the distances between points in the leg

            % forward acceleration integration
            for i = 1:size(dist,2)
                [forward_fx,forward_fy] = self.interp_force(self.car.friction_cone, forward_vels(i), radii(i), 1);    % forces at first apex
                forward_accels(i) = forward_fx/self.car.mass;
                if forward_accels(i) < 0
                    disp('neg accel')
                    forward_accels(i:size(dist,2)) = 0;
                    forward_vels(i+1:size(dist,2)+1) = forward_vels(i);
                    break
                end
                time = max(roots([forward_accels(i)/2 forward_vels(i) -dist(i)]));
                forward_vels(i+1) = forward_vels(i)+forward_accels(i)*time;
            end 

            figure
            plot([0 cumsum(dist)],forward_vels)
            xlabel('Distance (m)')
            ylabel('Velocity (m/s)')
            title('Forward Integrated Velocity from the Entry Apex')

            % reverse acceleration integration
            for j = 1:size(dist,2)
                [reverse_fx,reverse_fy] = self.interp_force(self.car.friction_cone, reverse_vels(j), radii(end+1-j), -1);   % forces at second apex
                reverse_accels(j) = reverse_fx/self.car.mass;
                if reverse_accels(j) > 0
                    disp('pos accel')
                    reverse_accels(j:size(dist,2)) = 0;
                    reverse_vels(j+1:size(dist,2)+1) = reverse_vels(j);
                    break
                end
                time = min(roots([reverse_accels(j)/2 reverse_vels(j) -dist(end+1-j)]));
                reverse_vels(j+1) = reverse_vels(j)-reverse_accels(j)*time;
            end

            integrated_vels = [forward_vels; fliplr(reverse_vels)];
            integrated_accels = [forward_accels; fliplr(reverse_accels)];

            vels = min(integrated_vels);
            leg_time = sum(dist./vels(1:end-1));
            accels = min(integrated_accels);
            
            leg_time = sum(dist./vels(1:end-1));
            self.time = self.time+leg_time;
            self.pos = self.pos+1;
        end
        
        function vel = calc_max_vel(self, r)
            % Calculates the maximum velocity (m/s) possible for a given
            % radius (m)
            [ind1, ind2] = self.find_closest_inds(self.min_rs(1, :), r);
            ps = self.min_rs(:, ind1:ind2);
            vel = interp1(ps(1,:), ps(2,:), r);
            
%             dv = self.min_rs(2, ind2) - self.min_rs(2, ind1);
%             dr = self.min_rs(1, ind2) - self.min_rs(1, ind1);
%             m = dv / dr;
%             vel = self.min_rs(2, ind1) + (r - self.min_rs(1, ind1)) * m;
        end
        
        function circle = interp_circle(self, cone, v)
            % Interpolates the friction circle for a given velocity within
            % the friction cone. 
            vs = squeeze(cone(3,1,:))';
            [ind1, ind2] = self.find_closest_inds(vs,v);
            
            v1 = vs(ind1);
            v2 = vs(ind2);
            
            circle1 = squeeze(cone(1:2, :, ind1));
            circle2 = squeeze(cone(1:2, :, ind2));
            circle = (circle2 - circle1) * (v - v1) / (v2 - v1) + circle1;
        end
        
        function [fx, fy] = interp_force(self, cone, v, r, acc)
            % Calculates max force fx, and fy given the velocity of the
            % car, the radius of the turn, and the direction of tangential
            % acceleration
           
            fy = v^2 * self.car.mass / r;               % Calculate the lateral force for the given velocity and turn radius
            circle = self.interp_circle(cone, v);       % Interpolate the friction circle for the given velocity
            valid_points = sortrows(circle(:, sign(circle(2, :)) ~= -sign(acc))')';      % Isolate the points for the given acceleration
            %fys = valid_points(1,:)                     % Isolate lateral force values from points
%             [minv, minindx] = min(fys);
%             [maxv, maxindx] = max(fys);
%             fys = fys(minindx:maxindx);
%             valid_points = valid_points(:,minindx:maxindx)
            %[ind1, ind2] = self.find_closest_inds(fys, fy)
            %ps = valid_points(:, ind1:ind2)
            % FIX LATER: ADD EXTRA ZERO CROSSING POINT SO WE DONT NEED TO
            % EXTRAPOLATE
            % [fy; fx] space
            fx = interp1(valid_points(1,:), valid_points(2,:), fy, 'linear')*2;
            
        end
        
        function [ind1, ind2] = find_closest_inds(self, arr, x)
            % finds the indices of arr that would be adjacent to element x 
            % if it were inserted into the array
            all_elements = sort([arr, x]);
            ind2 = find(all_elements == x);
            if ind2 > length(arr)
                ind2 = length(arr);
            end
            if ind2 == 1
                ind2 = 2;
            end
            ind1 = ind2 - 1;
           
        end
        
        function self = run_simulation(self)
            for i = 1:length(self.track.apex)-1
                self.calc_leg;
            end
            self.time
        end
        
    end
end
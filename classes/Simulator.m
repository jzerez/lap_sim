classdef Simulator
    properties
        car;            % Car object
        track;          % Track object
        pos = 0;        % Representing the apex number (integer)
        time = 0;       % Total Laptime (s)
        vels;
        accels;
        last_point_ind = 0;
        t_step = 0.01;  % timestep (s)
    end
    
    methods
        function self = Simulator(car, track)
            self.car = car;
            self.track = track;
            
            self.calc_min_rs();
            self.vels = zeros([1, self.track.num_points]);
            self.accels = zeros([1, self.track.num_points]);
        end
        
        function self = calc_leg(self)
            % Calculates the time between the current apex and the next
            % apex. Also updates current position 
            [points, radii] = self.track.get_points(self.pos);
            apex1_r = radii(1);
            apex2_r = radii(end);
            
            n_points = size(points, 2);
            
            vels = zeros([1, n_points]);
            accels = zeros([1, n_points]);
            
            v1 = self.calc_max_vel(apex1_r);
            v2 = self.calc_max_vel(apex2_r);
            
            for i = 1:n_points
                point = points(:, i);
                radius = radii(:, i);
                [fx, fy] = self.car.calc_forces(v, r)
            end
            
           
            
            
            self.pos = self.pos + 1;
        end
        
        function rs = calc_min_rs(self, cone)
            % Calculates minimum radius the car is capable of navigating
            % over a range of velocities. 
            max_fys = zeros([1, size(cone, 3)]);
            vs = squeeze(cone(3,1,:))';
            for index = 1:size(cone, 3)
                max_fys(index) = max(cone(2,:,index));
            end
            rs = vs.^2 * self.car.mass ./ max_fys;
            self.min_rs = [rs; vs];
        end
        
        function vel = calc_max_vel(self, cone, r)
            % Calculates the maximum velocity (m/s) possible for a given
            % radius (m)
            all_rs = sort([cone(3, :), r]);
            
            ind2 = find(all_rs == r);
            ind1 = ind2 - 1;
            dv = self.min_rs(2, ind2) - self.min_rs(2, ind1);
            dr = self.min_rs(1, ind2) - self.min_rs(1, ind1);
            m = dv / dr;
            vel = self.min_rs(2, ind1) + (r - self.min_rs(1, ind1)) * m;
        end
        
        function circle = interp_circle(self, cone, v)
            % Interpolates the friction circle for a given velocity within
            % the friction cone. 
            vs = squeeze(cone(3,1,:))';
            all_vs = sort([vs, v]);
            ind2 = find(all_vs == v);
            ind1 = ind2 - 1;
            
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
            
            fy = v^2 * self.car.mass / r;
            circle = self.interp_circle(cone, v);
            valid_points = circle(:, sign(circle(1, :)) == sign(acc));
            fys = valid_points(2,:);
            [ind1, ind2] = self.find_closest_inds(fys, fy);
            ps = valid_points(:, ind1:ind2);
            fx = interp1(ps(2,:), ps(1,:), fy);
            
        end
        
        function [ind1, ind2] = find_closest_inds(self, arr, x)
            % finds the indices of arr that would be adjacent to element x 
            % if it were inserted into the array
            all_elements = sort([arr, x]);
            ind2 = find(all_elements == x);
            ind1 = ind2 - 1;
        end
        
        
        
    end
end
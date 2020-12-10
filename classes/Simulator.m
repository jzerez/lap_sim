classdef Simulator < handle
    properties
        car;            % Car object
        track;          % Track object
        pos = 1;        % Representing the apex number (integer)
        time = 0;       % Total Laptime (s)
        vels;           % Maximum possible velocity at each track point
        accels;         % Maximum possible acceleration at each track point
        last_point_ind = 0;     
        min_rs;         % list of minimum radii for range of velocities
        t_step = 0.01;  % timestep (s)
        total_dist_traveled = 0;
        energy_used = 0 % Energy used per lap (kJ)
    end
    
    methods
        function self = Simulator(car, track)
            self.car = car;
            self.track = track;
            
            self.calc_min_rs(self.car.friction_cone);
            self.vels = [];
            self.accels = [];
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
%             scatter(points(1, :), points(2, :), 'k*')
            vels = zeros([1, n_points]);
            forward_vels = vels;
            reverse_vels = vels;
            accels = zeros([1, n_points]);
            forward_accels = accels;
            reverse_accels = accels; 
            
            
            forward_vels(1) = self.calc_max_vel(apex1_r);    % calculate the maximum possible velocity at the first apex
            reverse_vels(1) = self.calc_max_vel(apex2_r);    % calculate the maximum possible velocity at the second apex
            disp(forward_vels(1))
            dist = vecnorm(diff(points, 1, 2));  % calculates the distances between points in the leg

            % forward acceleration integration
            for i = 1:size(dist,2)
                [forward_fx,forward_fy] = self.interp_force(self.car.friction_cone, forward_vels(i), radii(i), 1);    % forces at first apex
                % drag force due to aero (should be negative!) (N)
                drag = self.car.aero.calc_drag(forward_vels(i));
%                 drag = 0;
                
                max_force = self.car.transmission.calc_max_force(forward_vels(i));
                if forward_fx < max_force
                    forward_fx = max_force;
                    disp('torque limited')
                end
                
                forward_fx = forward_fx * 2 + drag;
                %                 scatter3(forward_fy, forward_fx, forward_vels(i), 'r*')
                if forward_fx < 0 || self.car.transmission.max_vel < forward_vels(i)
                    forward_fx = 0;
                end
                
                
                forward_accels(i) = forward_fx/self.car.mass;
               
                inputs = [forward_accels(i)/2 forward_vels(i) -dist(i)];
                time = max(roots(inputs));
                next_vel = forward_vels(i)+forward_accels(i)*time;
                forward_vels(i+1) = next_vel;
            end 

            % reverse acceleration integration
            for j = 1:size(dist,2)
                [reverse_fx,reverse_fy] = self.interp_force(self.car.friction_cone, reverse_vels(j), radii(end+1-j), -1);   % forces at second apex
                
                
                
                drag = self.car.aero.calc_drag(reverse_vels(j));
                reverse_fx = reverse_fx * 4;
                
                if self.car.transmission.max_vel < reverse_vels(j)
                    reverse_fx = 0;
                end
                
                reverse_accels(j) = -reverse_fx/self.car.mass;
                 
                time = max(roots([reverse_accels(j)/2 reverse_vels(j) -dist(end+1-j)]));
                reverse_vels(j+1) = reverse_vels(j)+reverse_accels(j)*time;
            end

            integrated_vels = [forward_vels; fliplr(reverse_vels)];
            integrated_accels = [forward_accels; fliplr(reverse_accels)];

            vels = min(integrated_vels);
            energy_used = 0;
            for i = 1:length(dist)
                vel = vels(i)
                time = dist(i) / vel;
                energy_used = energy_used + time * self.car.transmission.calc_power(vel);
            end
            self.energy_used = self.energy_used + energy_used;
            leg_time = sum(dist./vels(1:end-1));
            accels = min(integrated_accels);
%             self.vels(self.track.apex(self.pos):self.track.apex(self.pos)+length(vels)-1) = vels;
%             self.accels(self.track.apex(self.pos):self.track.apex(self.pos)+length(accels)-1) = accels;
            self.vels = [self.vels, vels(1:end-1)];
            self.accels = [self.accels, accels(1:end-1)];
            self.time = self.time+leg_time;
            self.pos = self.pos+1;
            
            dist_vector = [0 cumsum(dist)] + self.total_dist_traveled;
            plot(dist_vector, forward_vels, '--', 'color', 	[0, 0.4470, 0.7410])
            plot(dist_vector, fliplr(reverse_vels), '--', 'color', [0.8500, 0.3250, 0.0980])
            plot(dist_vector, vels, 'color', [0.9290, 0.6940, 0.1250])
            plot([self.total_dist_traveled, self.total_dist_traveled], [0, 35], 'k-')
            self.total_dist_traveled = self.total_dist_traveled + sum(dist);
           
        end
        
        function vel = calc_max_vel(self, r)
            % Calculates the maximum velocity (m/s) possible for a given
            % radius (m)
%             [ind1, ind2] = self.find_closest_inds(self.min_rs(1, :), r);
%             ps = self.min_rs(:, ind1:ind2);
            vel = interp1(self.min_rs(1,:), self.min_rs(2,:), r);
            
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
            
           
            fy = v^2 * self.car.mass / r / 4;           % Calculate the lateral force for the given velocity and turn radius (PER TIRE)
            circle = self.interp_circle(cone, v);       % Interpolate the friction circle for the given velocity
%             scatter3(circle(1, :), circle(2,:), ones(size(circle(1,:)))*v, 'g*')
            valid_points = circle(:, sign(circle(2, :)) ~= -sign(acc));      % Isolate the points for the given acceleration
            fx = interp1(valid_points(1,:), valid_points(2,:), fy, 'linear');
            
            if isnan(fx) 
                disp('neg accel')
                if sign(acc) > 0
                    fx = max(valid_points(2,:));
                else
                    fx = min(valid_points(2,:));
                end
            end
            if sign(fx) ~= sign(acc) && fy ~= 0
                disp('wrong sign')
                fx = max(valid_points(2,:)) * sign(acc);
            end
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
            figure
            hold on
            for i = 1:length(self.track.apex)
                self.calc_leg();
            end
            self.vels = circshift(self.vels, self.track.apex(1));
            self.accels = circshift(self.accels, self.track.apex(1));
            xlabel('Distance (m)')
            ylabel('Velocity (m/s)')
            title('Velocity from the Entry Apex')
            legend(["Forward Integration", "Backwards Integration", "True Velocity", "Apex Locations"])
            self.time
        end
        
        function self = plot_velocity(self)
            
            zz = zeros([2, self.track.num_points]);
            figure
            hold on
            h = surf([self.track.points(1,:); self.track.points(1,:)], [self.track.points(2,:); self.track.points(2,:)],zz,[self.vels; self.vels],'EdgeColor','interp');
            set(h, 'LineWidth', 2.5)
            colormap jet
            colorbar
            hold off
            axis equal
            xlabel('(meters)')
            ylabel('(meters)')
        end
        
    end
end
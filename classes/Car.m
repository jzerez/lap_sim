classdef Car < handle
    properties
        mass;
        accumulator;
        transmission;
        frction_cone;
        aero;
        g = -9.81;      % m/s^2 (gravitational constant)
        
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
        
        function cone = calc_cone(self, tire, vels, num_alphas, num_forces)
            % Calculates the friction cone based off of tire data and aero.
            % This cone is a surface that represents the maximum
            % acceleration in the lateral and longitudinal direction that
            % is possible at any given velocity. 
            % 
            % Parameters: 
            %   tire: a char-array that represents the path to the .tir file to use
            %   vels: an array of velocities to calculate the cone with
            %   num_alphas: number of alpha values to sweep when calculating the cone (50 is good)
            %   num_forces: number of points that make up each profile of the cone 
            % 
            % Returns:
            %   cone: 2D matrix containing the points in [fx; fy; velocity]
            %   space that make up the friction cone. 
            
            % initialize vectors to store forces and velocities
            fxs = zeros([1, num_forces * length(vels)]);
            fys = zeros([1, num_forces * length(vels)]);
            vs = zeros([1, num_forces * length(vels)]);
            
            % sweep over velocities
            index = 1;
            figure
            hold on
            for vel = vels
                % calculate friction circle for specific velocity
                circle = self.calc_friction_circle(tire, vel, num_alphas, num_forces);
                % store calculated values
                zs = vel * ones([1, num_forces]);
                flat_index = (index - 1) * num_forces + 1;
                fys(flat_index:flat_index + num_forces - 1) = circle(1, :);
                fxs(flat_index:flat_index + num_forces - 1) = circle(2, :);
                vs(flat_index:flat_index + num_forces - 1) = zs;
                plot3(circle(1, :), circle(2, :), zs, 'k--')
                index = index + 1;
            end
            scatter3(fys, fxs, vs, 'bo')
            xlabel('Lateral Force F_y (N)')
            ylabel('Longitudinal Force F_x (N)')
            zlabel('Velocity (m/s)')
            cone = zeros([3, num_forces * length(vels)]);
            cone(1, :) = fxs;
            cone(2, :) = fys;
            cone(3, :) = vs;
        end
        
        function circle = calc_friction_circle(self, tire, vel, num_alphas, num_forces)
            % Calculates the friction circle for a given velocity
            % 
            % Parameters: 
            %   tire: a char-array that represents the path to the .tir file to use
            %   vels: an array of velocities to calculate the cone with
            %   num_alphas: number of alpha values to sweep when calculating the cone (50 is good)
            %   num_forces: number of points that make up each profile of the cone 
            %
            % Returns:
            %   circle: a 2D matrix in [fx; fy] space that represents the points along the friction circle
           
            % Number of slip ratio values to sweep
            num_samples = 1000;
            % Normal force (N)
            % Need to be positive!!
            Fz = -(self.mass * self.g + self.aero.calc_lift(vel)) ./ 4;
            % Fz = -self.mass * self.g;
            disp(self.aero.calc_lift(vel) / (self.mass * self.g))
            Fzs = ones([1, num_samples]) * Fz;
            
            % Slip Ratios (dimensionless, -1: locked wheel)
            kappas = linspace(-1, 1, num_samples);
            
            % Camber angles (radians)
            gammas = zeros([1, num_samples]);
            
            % Turnslip (1/m)
            % This doesn't seem to have any impact on the tires
            phits = ones([1, num_samples]);
            
            % Velocities (m/s)
            % This doesn't have an impact on the force calculated by dteval
            vxs = ones([1, num_samples]) * vel;
            
            % slip angles (radians)
            alphas_to_sweep = linspace(0, deg2rad(12), num_alphas);
            
            % A collection of Friction circle curves. 
            % The first dimension represents the [r;theta] values of a given
            % point in lateral-longitudinal force space
            % The second dimension represents the slip ratio values that
            % are swept over
            % The thrid dimension represents the slip angle values that are
            % swept over
            curves = zeros([2, num_samples, num_alphas]);
            index = 0;
%             figure
%             xlabel('Lateral Force F_y (N)')
%             ylabel('Longitudinal Force F_x (N)')
%             title('Friction Circle Family')
%             hold on

            for alpha = alphas_to_sweep
                index = index + 1;
                alphas = ones([1, num_samples]) * alpha;
                
                % Initialize inputs and calculate tire forces
                % The force being calculated here is over a wide range of
                % slip ratios and for a specific alpha and Fz. 
                inputs = [Fzs', kappas', alphas', gammas', phits', vxs'];
                tire_res = dteval(tire, inputs, 4);
                
                
                
                % Lateral Forces
                fys = -squeeze(tire_res(:,2,:));
                % Longitudinal Forces
                fxs = squeeze(tire_res(:,1,:));
%                 plot(fys, fxs, 'b-')
                
                % Convert to polar coordinates
                [thetas, rs] = cart2pol(fys, fxs);
                
                % The resulting curve that represents the friction curve
                % over a wide range of slip ratios and for a specific slip
                % angle and specific normal force. 
                curves(:, :, index) = [rs'; thetas'];
            end
            % Calculate the max envelope of all of the curves
            circle = self.fit_friction_circle(curves, num_forces);
%             
%             scatter(circle(1, :), circle(2,:), 'k*')
            
            
        end
        
        function circle = fit_friction_circle(self, curves, num_points)
            % Calculate the max envelope of a set of all curves in polar
            % coordinates. 
            % 
            % Parameters:
            %   curves: a 3D matrix containing a family of curves
            %   containing friction curve info over a range of slip ratios
            %   and slip angles
            %   num_points: The number of points to fit in the max friction envelope
            
            % Returns:
            %   circle: The maximum envelope of a set of all curves. In
            %   otherwords, the maximum radius for any given theta.
            %   returned in [fy; fx] space
            
            % Theta values to sweep in radians
            thetas = linspace(-pi/2, pi/2, num_points);
            
            % radius values from the family of curves
            curve_rs = curves(1, :, :);
            % theta values from the family of curves
            curve_thetas = curves(2, :, :);
            % max radii for each theta
            rs = zeros(size(thetas));
            index = 1;
            for theta = thetas
                % Find the closest theta value present in each curve
                [~, closest_theta_inds] = min(abs(curve_thetas - theta));
                % Flatten the indices
                closest_theta_inds = squeeze(closest_theta_inds)';

                L = length(closest_theta_inds);
                % Create indices to select the radii corresponding to the
                % theta values
                inds = sub2ind(size(curve_rs), ones([1,L]), closest_theta_inds, 1:L);
                % Find the highest radius value in the family of curves
                % that matches the current theta value
                rs(index) = max(curve_rs(inds));
                index = index + 1;
            end
            [fys, fxs] = pol2cart(thetas, rs);
            circle = [fys; fxs];
        end
    end
end
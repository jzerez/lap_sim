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
            fxs = zeros([1, num_forces * length(vels)]);
            fys = zeros([1, num_forces * length(vels)]);
            vs = zeros([1, num_forces * length(vels)]);
            
            index = 1;
            for vel = vels
                
                circle = self.calc_friction_circle(tire, vel, num_alphas, num_forces);
                zs = vel * ones([1, num_forces]);
                flat_index = (index - 1) * num_forces + 1;
                fxs(flat_index:flat_index + num_forces - 1) = circle(1, :);
                fys(flat_index:flat_index + num_forces - 1) = circle(2, :);
                vs(flat_index:flat_index + num_forces - 1) = zs;
                index = index + 1;
            end
            scatter3(fxs, fys, vs)
            cone = zeros([3, num_forces * length(vels), length(vels)]);
            cone(1, :, :) = fxs;
            cone(2, :, :) = fys;
            cone(3, :, :) = vs;
        end
        
        function circle = calc_friction_circle(self, tire, vel, num_alphas, num_forces)
%             Fz = self.mass * self.g + self.aero.calc_lift(vel);
            num_samples = 200;
            Fz = -self.mass * self.g;
            kappas = linspace(-1, 1, num_samples);
            Fzs = ones(size(kappas)) * Fz;
            gammas = zeros([1, num_samples]);
            phits = ones([1, num_samples]);
            vxs = ones([1, num_samples]) * vel;
            alphas_to_sweep = linspace(0, deg2rad(12), num_alphas);
            
            curves = zeros([2, num_samples, num_alphas]);
            index = 0;
            figure
            hold on
            l = cell([1, num_alphas]);
            for alpha = alphas_to_sweep
                index = index + 1;
                l{index} = num2str(alpha);
                alphas = ones([1, num_samples]) * alpha;
                
                inputs = [Fzs', kappas', alphas', gammas', phits', vxs'];
                tire_res = dteval(tire, inputs, 4);
                fys = squeeze(tire_res(:,2,:));
                fxs = squeeze(tire_res(:,1,:));
                
                [thetas, rs] = cart2pol(fxs, fys);
                
                curves(:, :, index) = [rs'; thetas'];
            end
            circle = self.fit_friction_circle(curves, num_forces);
            
        end
        
        function circle = fit_friction_circle(self, curves, num_points)
            thetas = linspace(-pi, 0, num_points);
            curve_rs = curves(1, :, :);
            curve_thetas = curves(2, :, :);
            rs = zeros(size(thetas));
            index = 1;
            for theta = thetas
                [~, closest_theta_inds] = min(abs(curve_thetas - theta));
                closest_theta_inds = squeeze(closest_theta_inds)';
                L = length(closest_theta_inds);
                inds = sub2ind(size(curve_rs), ones([1,L]), closest_theta_inds, 1:L);
                rs(index) = max(curve_rs(inds));
                index = index + 1;
            end
            [xs, ys] = pol2cart(thetas, rs);
            circle = [xs; ys];
            figure
            polarplot(thetas, rs)
        end
    end
end
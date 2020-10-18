classdef ScoreCalculator < handle
    %SCORECALCULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        base_acceleration_times = [];
        base_acceleration_scores = [];
        base_skidpad_times = [];
        base_skidpad_scores = [];
        base_autocross_times = [];
        base_autocross_scores = [];
        base_endurance_times = [];
        base_endurance_scores = [];
        base_efficiency_epls = [];       % Base efficiency energy per lap
        base_efficiency_scores = [];
        
    end
    
    methods
        function self = ScoreCalculator(competition_info_files)
            %SCORECALCULATOR Construct an instance of this class
            %   Detailed explanation goes here
            
            % Load in the competition info for each of the competitions
            for index = 1:length(competition_info_files)
                file = competition_info_files(index);
                load(char(file));
                self.base_acceleration_times = [self.base_acceleration_times, acceleration_times];
                self.base_acceleration_scores = [self.base_acceleration_scores, acceleration_scores];
                
                self.base_skidpad_times = [self.base_skidpad_times, skidpad_times];
                self.base_skidpad_scores = [self.base_skidpad_scores, skidpad_scores];
                
                self.base_autocross_times = [self.base_autocross_times, autocross_times];
                self.base_autocross_scores = [self.base_autocross_scores, autocross_scores];
                
                self.base_endurance_times = [self.base_endurance_times, endurance_times];
                self.base_endurance_scores = [self.base_endurance_scores, endurance_scores];
                
                self.base_efficiency_epls = [self.base_efficiency_epls, efficiency_energy_per_lap];
                self.base_efficiency_scores = [self.base_efficiency_scores, efficiency_scores];
            end
            
            
        end

        function [score, scores] = calc_acc_score(self, time)
            [score, scores] = self.calc_score(@self.acc_func, 1.5, 4.5, time, self.base_acceleration_times);
        end
        
        function [score, scores] = calc_skidpad_score(self, time)
            [score, scores] = self.calc_score(@self.skidpad_func, 1.25, 3.5, time, self.base_skidpad_times);
        end
        
        function [score, scores] = calc_autocross_score(self, time)
            [score, scores] = self.calc_score(@self.autocross_func, 1.45, 6.5, time, self.base_autocross_times);
        end
        
        function [score, scores] = calc_endurance_score(self, time)
            [score, scores] = self.calc_score(@self.endurance_func, 1.45, 25, time, self.base_endurance_times);
        end
        
        function [score, scores] = calc_efficiency_score(self, energy_used)
            [score, scores] = self.calc_score(@acc_func, 1.5, 4.5, time, self.base_acceleration_times);
        end
        
        function [score, scores] = calc_score(self, event_function, tmax_ratio, min_score, time, times)
            %CALC_ACC_SCORES: Takes a time for the acceleration event and calculates
            %the score relative to other teams' times. 
            
            all_times = sort([times, time]);
            tmin = min(all_times);
            tmax = tmin * tmax_ratio;

            scores = event_function(tmax, tmin, all_times);
            scores(all_times > tmax) = min_score;
            score = scores(all_times == time);
        end
        
        function scores = acc_func(self, tmax, tmin, times)
            scores = 95.5 .* (tmax./times - 1) ./ (tmax ./ tmin - 1) + 4.5;
        end
        
        function scores = skidpad_func(self, tmax, tmin, times)
            scores = 71.5 .* ((tmax./times).^2 - 1) ./ ((tmax ./ tmin).^2 - 1) + 3.5;
        end
        
        function scores = autocross_func(self, tmax, tmin, times)
            scores = 118.5 .* (tmax ./ times - 1) ./ (tmax ./ tmin - 1) + 6.5;
        end
        
        function scores = endurance_func(self, tmax, tmin, times)
            scores = 250 .* (tmax ./ times - 1) ./ (tmax ./ tmin - 1) + 25;
        end
        
        function scores = efficiency_func(self, tmax, gay)
            scores = 250 .* (tmax ./ times - 1) ./ (tmax ./ tmin - 1) + 25;
        end
    end
end


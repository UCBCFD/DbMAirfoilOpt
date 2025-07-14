function [state,options,optchanged] = gaoutfun(options,state,~)
	opt_dir = 'optResults';
	writematrix(state.Population, fullfile(opt_dir, ['CurrentPopulation_' sprintf('%04d', state.Generation) '.txt']),'Delimiter',' ');
	writematrix(state.Score, fullfile(opt_dir,['CurrentPopulationScore_' sprintf('%04d', state.Generation) '.txt']),'Delimiter',' ');
	writematrix(state.Population,fullfile(opt_dir,'TotalPopulation.txt'),'Delimiter',' ','WriteMode','append');
	writematrix(state.Score,fullfile(opt_dir,'TotalPopulationScore.txt'),'Delimiter',' ','WriteMode','append');
	optchanged = false;
end
function out=airfoil_wrapper(x)

weights_str = sprintf('%.8f ', x);

original_matlab_path = pwd;
workspace_dir = fullfile(original_matlab_path, '.workSpace'); 
if ~exist(workspace_dir, 'dir') 
    mkdir(workspace_dir)
end
i_string = fullfile(workspace_dir, strcat(strrep(weights_str,' ','_'),string(java.util.UUID.randomUUID)));
airfoil_source_dir = fullfile(original_matlab_path, 'airfoilEval');
if ~isfolder(airfoil_source_dir)
    error('Source Airfoil directory not found at: %s. Ensure AirOptimizer.m is run from the project root.', airfoil_source_dir);
end
copyfile(airfoil_source_dir, i_string);
cd(i_string);

venv_dir_relative_to_project_root = 'venv';
python_in_venv = fullfile(venv_dir_relative_to_project_root, 'bin', 'python');
python_executable = fullfile(original_matlab_path, python_in_venv);

python_script_dir = fullfile(original_matlab_path, 'pyRunDbM');
python_script_file = fullfile(python_script_dir, 'main.py');

if ~isfile(python_executable)
    error('Python executable in virtual environment not found at: %s', python_executable);
end
if ~isfile(python_script_file)
    error('Python script not found at: %s', python_script_file);
end

command = sprintf('"%s" "%s" %s', python_executable, python_script_file, weights_str);

[status, cmdout] = system(command);

CLD_max_val = 0; delta_alpha_stall_val = 0;
error_flag = 0;

if status == 0
    current_eval_path = pwd;
    addpath(fullfile(current_eval_path)); 
	try
        new_coords = load('airfoil_coords.dat');
        [CLD_max_val, delta_alpha_stall_val] = airfoil_func_calls(new_coords);
    catch ME
        disp('Error processing Python output or calling airfoil_func_calls:');
        disp(ME.message);
        CLD_max_val = 0; delta_alpha_stall_val = 0;
        error_flag = 33;
    end
    rmpath(fullfile(current_eval_path));
else
    disp(['Python script execution failed for weights: ' weights_str]);
    disp('Python stdout/stderr:');
    disp(cmdout);
    CLD_max_val = 0; delta_alpha_stall_val = 0;
    error_flag = 44;
end

if CLD_max_val > 300 || CLD_max_val < 0
    CLD_max_val = 0; delta_alpha_stall_val = 0;
    error_flag = 55; 
end

% ERROR FLAG:
% 33: error processing Python (morphing) or calling airfoil_func_calls
% 44: Python (morphing) execution failed
% 55: Unrealistic CLD_max_val
% fid = fopen('./debug', 'w');
% fprintf(fid, '%d %f %f', error_flag, CLD_max_val, delta_alpha_stall_val);
% fclose(fid);

cd(original_matlab_path);
rmdir(i_string,'s');

out=[-1*CLD_max_val, -1*delta_alpha_stall_val];
end

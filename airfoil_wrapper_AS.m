function out=airfoil_wrapper_AS(x)

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

delta_alpha_stall_val = 0;
error_flag = 0;

if status == 0
    current_eval_path = pwd;
    addpath(fullfile(current_eval_path)); 
    try
        new_coords = load('airfoil_coords.dat');
        delta_alpha_stall_val = airfoil_func_calls_AS(new_coords);
    catch ME
        disp('Error processing Python output or calling airfoil_func_calls_AS:');
        disp(ME.message);
        delta_alpha_stall_val = 0;
        error_flag = 33;
    end
    rmpath(fullfile(current_eval_path));
else
    disp(['Python script execution failed with weights: ' weights_str]);
    disp('Python stdout/stderr:');
    disp(cmdout);
    delta_alpha_stall_val = 0;
    error_flag = 44;
end






% ERROR FLAG:
% 33: error processing Python (morphing) or calling airfoil_func_calls
% 44: Python (morphing) execution failed

% fid = fopen('./debug', 'w');
% fprintf(fid, '%d %f', error_flag, delta_alpha_stall_val);
% fclose(fid);

cd(original_matlab_path);
rmdir(i_string,'s');

out = -1*delta_alpha_stall_val;
end

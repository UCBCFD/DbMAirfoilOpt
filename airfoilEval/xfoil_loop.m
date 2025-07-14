function [CLD,CL,alpha_list,miss_count] = xfoil_loop(alpha,alpha_end,alpha_step,miss_threshold,foilname)
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LOAD AIRFOIL PROFILE AND CALCULATE CL/CD, CL, ALPHA
    % USAGE:
    % foilname: 'NACA 2142'
    % or foilnamme: 'load xxx.dat'
    % NOTE:
    % 1. XFOIL skips an angle when it does not converge and aborts if 4
    % consecutive angles all fail to converge;
    % 2. This code starts a new XFOIL run (wipe out previous memory) whenever
    % a previous XFOIL run aborts until EITHER alpha_end is reached OR
    % miss_threshold numbers of consecutive XFOIL runs fail to generate any
    % result.
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Initialize output variables for all return paths
    CLD = [];
    CL = [];
    alpha_list = [];
    miss_count = 0;

    % ONE-SIDED ONLY
    if alpha*alpha_end < 0
        disp('xfoil_loop: angles must be either all postive or all negative');
        return
    end

    % OPEN XFOIL INPUT FILE
    fid = fopen('./XFOIL/xfoilInput.input','r');
    if fid == -1
        % Output variables are already initialized to empty/zero
        return;
    end

    i = 1;
    tline = fgetl(fid);
    A{i} = tline;
    while ischar(tline)
        i = i+1;
        tline = fgetl(fid);
        A{i} = tline;
    end
    fclose(fid);

    % SET THE FOIL FILENAME
    if exist('foilname','var') && ~isempty(foilname)
        A{4} = foilname;
    else
        A{4} = 'load XFOIL/morphed_repanel.txt';
    end

    % CALCULATION
    alpha_return = 0; % Local variable, will be overwritten by xfoil_alpha's output
    alpha_start = alpha;
    break_counter = 0;

    while abs(alpha_start)*sign((alpha_start+alpha_end)*alpha_step) ...
            <= abs(alpha_end)*sign((alpha_start+alpha_end)*alpha_step) && break_counter <= 100
        
        break_counter = break_counter+1;
        
        [output,alpha_return] = xfoil_alpha(alpha_start, A, 'all', alpha_end, alpha_step);
        
        if ~isempty(alpha_return) 
            alpha_start = alpha_return(end) + alpha_step;
            alpha_list = [alpha_list;alpha_return(:)];
            CLD = [CLD;output(:,1)];
            CL = [CL;output(:,2)];
            miss_count = 0; 
        else 
            alpha_start = alpha_start + alpha_step; 
            miss_count = miss_count+1;
        end
        
        if miss_count >= miss_threshold
            return % xfoil_loop's maximum failed attempts reached
        end
        
        if alpha_step == 0 || alpha_start == alpha_end
            return
        end
        
    end

    if break_counter == 100
        disp(break_counter)
    end
end
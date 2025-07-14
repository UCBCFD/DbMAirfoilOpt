function [CLD_max,alpha_CLD_max,CL_max,alpha_stall,error_flag] = xfoil_scan(foilname)
    % Initialize output variables
    CLD_max = NaN;
    alpha_CLD_max = NaN;
    CL_max = NaN;
    alpha_stall = NaN;
    error_flag = 0; 

    % DEFAULT PARAMETERS
    alpha_start = 0;
    alpha_end = 40;
    alpha_step_coarse = 1;
    alpha_step_fine = 0.25;
    miss_threshold = 12;
    alpha_count_fine_CLD = 4;
    alpha_count_fine_CL = 1;

    % INITILIZATION 
    if nargin < 1
        foilname = []; 
    end

    % COARSE SEARCH
    [CLD,CL,alpha_list,~] = xfoil_loop(alpha_start,alpha_end,alpha_step_coarse,miss_threshold,foilname);
    if isempty(CLD)
        alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
        error_flag = 311; 
        return
    elseif ~isnumeric(CLD)
        alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
        error_flag = 312; 
        return
    elseif ~isnumeric(CL) || isempty(CL)
        alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
        error_flag = 313; 
        return
    end
    [CLD_max_coarse,index_CLD_max_coarse] = max(CLD);
    [~,index_CL_max] = max(CL); 
    miss_threshold = 8; 

    % FINE SEARCH for CLD_max:
    [CLD_R,~,alpha_CLD_list_R,~] = xfoil_loop(alpha_list(index_CLD_max_coarse), ...
        alpha_list(min(index_CLD_max_coarse+alpha_count_fine_CLD,numel(alpha_list))), ...
        alpha_step_fine,miss_threshold,foilname);

    if isempty(CLD_R) || ~isnumeric(CLD_R) || ...
       (alpha_list(index_CLD_max_coarse)+alpha_step_coarse == alpha_list(min(index_CLD_max_coarse+1,numel(alpha_list))) && ...
        ~ismember(alpha_list(index_CLD_max_coarse)+alpha_step_coarse,alpha_CLD_list_R) )  
        alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
        error_flag = 321;
        return
    end
    if abs(CLD_R(1)-CLD_max_coarse) > 15 
        alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
        error_flag = 322;
        return
    end
    [CLD_L,~,alpha_CLD_list_L,~] = xfoil_loop(alpha_list(index_CLD_max_coarse), ...
        alpha_list(max(index_CLD_max_coarse-alpha_count_fine_CLD,1)), ...
        -alpha_step_fine,miss_threshold,foilname);
    if isempty(CLD_L) || ~isnumeric(CLD_L) || ...
       (alpha_list(index_CLD_max_coarse)-alpha_step_coarse == alpha_list(max(index_CLD_max_coarse-1,1)) && ...
        ~ismember(alpha_list(index_CLD_max_coarse)-alpha_step_coarse,alpha_CLD_list_L) )
        alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
        error_flag = 323;
        return
    end
    CLD = [CLD_L(:);CLD_R(:)]; 
    alpha_CLD_list = [alpha_CLD_list_L(:);alpha_CLD_list_R(:)];
    if isempty(CLD)
        alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
        error_flag = 324; 
        return
    elseif ~isnumeric(CLD)
        alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
        error_flag = 325; 
        return
    end

    [CLD_max,index_CLD_max] = max(CLD); 
    alpha_CLD_max = alpha_CLD_list(index_CLD_max);

    % CONVERGENCE CHECK for CLD_max:
    if CLD_max-CLD_max_coarse > 15 ...
    || CLD_max < CLD_max_coarse ...
    || abs(alpha_CLD_max-alpha_list(index_CLD_max_coarse)) > 2
        
        [CLD_max_2,~,~,~] = xfoil_loop(alpha_CLD_max,alpha_CLD_max,0,miss_threshold,foilname);
        
        if isempty(CLD_max_2) || ~isnumeric(CLD_max_2) ...
        || abs(CLD_max_2-CLD_max_coarse) > 15 ...
        || abs(CLD_max_2-CLD_max) > 15 
            alpha_CLD_max = NaN; CLD_max = NaN; alpha_stall = NaN; CL_max = NaN;
            error_flag = 331;
            return
        else
            CLD_max = CLD_max_2;
        end
    end

    % FINE SEARCH for alpha_stall:
    miss_threshold = 4;
    [~,CL,alpha_CL_list,~] = xfoil_loop(alpha_CLD_max, ...
        max(alpha_list(min(index_CL_max+alpha_count_fine_CL,numel(alpha_list))), ...
            alpha_CLD_max+alpha_step_fine), ...
        alpha_step_fine,miss_threshold,foilname);
    if isempty(CL)
        alpha_stall = NaN; CL_max = NaN;
        error_flag = 341; 
        return
    elseif ~isnumeric(CL)
        alpha_stall = NaN; CL_max = NaN;
        error_flag = 342; 
        return
    end
    if isempty(CL) || isempty(alpha_CL_list) % Guard for direct indexing below
        alpha_stall = NaN; CL_max = NaN; 
        error_flag = 343;
        return;
    end
    count_CL_max = 0;
    index_CL = 1; 
    CL_max = CL(1); 
    alpha_stall = alpha_CL_list(1);
    while index_CL <= numel(alpha_CL_list)-1
        index_CL = index_CL+1;
        if CL(index_CL) > CL_max
            CL_max = CL(index_CL);
            alpha_stall = alpha_CL_list(index_CL);
            count_CL_max = 0;
        else
            count_CL_max = count_CL_max + 1;
            if CL(index_CL) <= 0.9*CL_max
                return
            end
        end
        if count_CL_max >= min(5,numel(alpha_CL_list)) 
            return
        end
    end
end
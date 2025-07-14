function [CLD_max, delta_alpha_stall]=airfoil_func_calls(M)
    error_flag = -1;

    panel_default = 100;
    panel_level = 0;
    panel_step = 50;
    break_counter = 0;

    M_copy = M;
    while ((error_flag < 0) && (panel_level < 3) && (break_counter < 5))
        break_counter = break_counter + 1;
        panel_current = panel_default + panel_level * panel_step;
        [M] = panelling(M_copy, panel_current);

        if (numel(M(:,1)) > 495) % 495 is the max num of panel nodes allowed in XFOIL
            M_undersampled = M(1:ceil(numel(M(:,1))/495):end,:);
        else
            M_undersampled = M;
        end

        le = find(M_undersampled(:,1)==min(M_undersampled(:,1))); le = le(1);
        M_undersampled(:,1) = M_undersampled(:,1) - M_undersampled(le,1);
        M_undersampled=M_undersampled / M_undersampled(1,1);

        system('rm ./XFOIL/morphed_repanel.txt &> /dev/null');
        fid = fopen('./XFOIL/morphed_repanel.txt', 'w');
        for i = 1:numel(M_undersampled(:,1))
            fprintf(fid,'%15.12f %15.12f\n', M_undersampled(i,:));
        end
        fclose(fid);

        [CLD_max,CLD_alpha_max,~,alpha_stall,error_flag] = xfoil_scan();
        delta_alpha_stall = alpha_stall - CLD_alpha_max;
        if delta_alpha_stall < 0
            delta_alpha_stall = 0
        end

        if (error_flag > 0)
            CLD_max = 0;
            delta_alpha_stall = 0;
        else
            panel_level = panel_level + 1;
        end
    end

    if (panel_level >= 3) % Can't refine the panel towards convergence
        CLD_max = 0; 
        delta_alpha_stall = 0;
        error_flag = 77;
    end

    % ERROR FLAG:
    % 77: maximum panel level reached and still no convergence 
    % (note: if too many panel pts, XFOIL leads to numerical artifact)
    % 3XX: error flags from xfoil_scan
    if (error_flag > 0)
        fid = fopen('./err.flg', 'w');
        fprintf(fid, '%d', error_flag);
        fclose(fid);
    end
end 
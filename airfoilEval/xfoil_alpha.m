function [output,alpha_return] = xfoil_alpha(alpha, A, flag, alpha_end, alpha_step)
    alpha_return=[];

    % UPDATE XFOIL'S INPUT
    if ~exist('alpha_end','var')
        A{13} = sprintf('alfa %g',alpha);
    else
        A{13} = sprintf('aseq %g %g %g',[alpha,alpha_end,alpha_step]);
    end

    fid = fopen('./XFOIL/xfoilInput.input', 'w');
    if fid == -1
        output = 0;
        alpha_return = [];
        return;
    end
    % Assuming A is structured such that A{i+1} is always valid for access
    % until A{i+1} == -1, and -1 sentinel causes loop to break.
    for i = 1:numel(A)
        if (i+1) > numel(A) % Guard against A{i+1} if i is last element
            if ischar(A{i}) && ~isequal(A{i}, -1) % If last element is a command
                 fprintf(fid,'%s\n', A{i});
            end
            break;
        end

        if isequal(A{i+1}, -1)
            if ischar(A{i})
                fprintf(fid,'%s', A{i});
            end
            break
        else
            if ischar(A{i})
                fprintf(fid,'%s\n', A{i});
            end
        end
    end
    fclose(fid);

    system('rm -f ./XFOIL/xfoilDump > /dev/null 2>&1');
    system('rm -f ./XFOIL/xfoilSave.txt > /dev/null 2>&1');

    results=evalc(sprintf('system(''./xfoil < ./XFOIL/xfoilInput.input > /dev/null 2>&1'')')); % results is unused

    fid = fopen('./XFOIL/xfoilSave.txt', 'r');
    if fid == -1
        output = 0;
        return
    end

    header = textscan(fid,'%s',7,'HeaderLines',10);
    header = char(header{1,1});
    frewind(fid);
    data_raw = textscan(fid,'%f %f %f %f %f %f %f %f %f','HeaderLines',12);
    data_raw = cell2mat(data_raw);
    fclose(fid);

    % if ~isempty(data_raw)
    %     append_command = sprintf('cat ./XFOIL/xfoilSave.txt >> ./XFOIL/xfoilSaveHistory.txt');
    %     if isfile('./XFOIL/xfoilSave.txt')
    %         system(append_command);
    %     end
        
    %     fid_hist = fopen('./XFOIL/xfoilSaveHistory.txt', 'a');
    %     if fid_hist ~= -1
    %         fprintf(fid_hist, '\n');
    %         fclose(fid_hist);
    %     end
    % else
    %     % If data_raw is empty, XFOIL might have failed or produced no converged points.
    %     % In this case, we won't append to history.
    %     % The logic below will handle setting output = 0 if applicable.
    % end

    data = struct();
    if ~isempty(data_raw) && size(data_raw,2) >= 7 && size(header,1) >=7
        for i = 1:7
            name = strtrim(convertCharsToStrings(header(i,:)));
            if ~isempty(name)
                 valid_name = matlab.lang.makeValidName(name);
                 data.(valid_name) = data_raw(:,i);
            end
        end
    end

    if isfield(data,'CL') && ~isempty(data.CL) && isfield(data,'CD') && ~isempty(data.CD) && isfield(data,'alpha') && ~isempty(data.alpha)
        CLD = data.CL./data.CD;
        CL = data.CL;
        alpha_return = data.alpha;
    elseif isfield(data,'CL') && ~isempty(data.CL) && isfield(data,'alpha') && ~isempty(data.alpha) % CD might be missing
        CLD = 0;
        CL = data.CL;
        alpha_return = data.alpha;
    else
        CLD = 0;
        CL = 0;
        alpha_return = []; % Ensure alpha_return is empty if no valid data
    end

    if strcmpi(flag,'CLD')
        output = CLD;
    elseif strcmpi(flag,'CL')
        output = CL;
    elseif strcmpi(flag,'all')
        if numel(CLD) == numel(CL) && ~isempty(CL) % Ensure CL is not empty for valid pairing
            output = [CLD(:),CL(:)];
        elseif isscalar(CLD) && CLD == 0 && ~isempty(CL) % CD was likely missing, CLD defaulted to 0
            output = [zeros(size(CL(:))), CL(:)];
        else % Inconsistent or all empty data for CLD/CL pairing
            output = nan; % Default to NaN for this branch
            if isempty(CL) && isempty(CLD) % If truly no data resulted in CL/CLD from data struct
                output = 0; % Match behavior if CL/alpha empty from earlier logic
            end
        end
    else
        output = nan; % Unknown flag
    end

    % If output ended up as nan (e.g. from 'all' flag logic or unknown flag) 
    if all(isnan(output(:))) && isempty(alpha_return)
        output = 0;
    end
end
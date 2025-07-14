n_processors=128;
maxNumCompThreads(1);

current_eval_path = pwd;
addpath(fullfile(current_eval_path)); 

nvars = 12;
lb=-1*ones(1,nvars);
ub=ones(1,nvars);

parpool(n_processors,'IdleTimeout', Inf)

if not(isfile('GAOutput_SO.mat'))
    gen_intial=zeros(2,nvars);
    gen_intial_opt=zeros(2,1);  

    options = optimoptions('ga','ConstraintTolerance',1e-6,'MaxGenerations',100, 'PopulationSize',128,'UseParallel',true, 'UseVectorized', false, 'InitialPopulationMatrix', eye(nvars),'Display','iter','OutputFcn',@gaoutfun);
    [gen_intial(1,:),gen_intial_opt(1)]= ga(@(x) airfoil_wrapper_CLD(x),nvars,[],[],[],[],lb,ub,[],options);

    options = optimoptions('ga','ConstraintTolerance',1e-6,'MaxGenerations',100,'PopulationSize',128,'UseParallel',true, 'UseVectorized', false, 'InitialPopulationMatrix', eye(nvars),'Display','iter','OutputFcn',@gaoutfun);
    [gen_intial(2,:),gen_intial_opt(2)]= ga(@(x) airfoil_wrapper_AS(x),nvars,[],[],[],[],lb,ub,[],options);

    gen_intial=vertcat(gen_intial,eye(nvars));

    save('GAOutput_SO.mat', 'gen_intial', 'gen_intial_opt')
else

    if not(isfile('GAOutput_MO.mat'))
        SO=load('GAOutput_SO.mat');
        gen_intial=SO.gen_intial;
        gen_no=0;
    else
        MO=load('GAOutput_MO.mat');
        gen_intial=unique(MO.population,'rows');
        gen_no=MO.gen_no;
    end
    
    if size(gen_intial, 2) ~= nvars
        warning('Loaded initial population has %d variables, but nvars is %d. GA might error or behave unexpectedly. Consider deleting GAOutput_SO.mat and GAOutput_MO.mat.', size(gen_intial, 2), nvars);
    end

    options = optimoptions('gamultiobj','DistanceMeasureFcn',{@distancecrowding,'phenotype'},'ConstraintTolerance',1e-4,'MaxGenerations',500,'PopulationSize',376,'UseParallel',true, 'UseVectorized', false, 'InitialPopulationMatrix', gen_intial,'Display','iter','OutputFcn',@gaoutfun, 'FunctionTolerance',1e-8, 'MaxTime', 172000);
    [x_opt,fval,exitflag,output,population,scores] = gamultiobj(@(x) airfoil_wrapper(x),nvars,[],[],[],[],lb,ub,[],options);
    gen_no=gen_no+output.generations;

    save('GAOutput_MO.mat', 'x_opt', 'fval', 'exitflag', 'output', 'population', 'scores', 'gen_no')
end

poolobj = gcp('nocreate');
delete(poolobj);

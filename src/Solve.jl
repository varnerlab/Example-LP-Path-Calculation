function solve(network::MyStoichiometricMatrixModel; 
    exclude::Set{Int64} = Set{Int64}())::Dict{String,Any}

    # initialize -
    results = Dict{String,Any}();
    S = network.matrix;
    bounds = network.bounds |> copy;
    r = network.reactions |> (x -> length(x));  
    m = network.species |> (x -> length(x));  

    # update the bounds, where we exclude forbidden reactions -
    for i ∈ exclude
        bounds[i,1] = 0.0;
        bounds[i,2] = 0.0;
    end

    # setup c and b vectors -
    c = ones(r); # we are looking for the shortest path from source to target, so let vector equal 1
    b = zeros(m); # we are formulating this with a "boundary" layer, so b = 0 for all nodes

    # Setup the problem -
    model = Model(GLPK.Optimizer)
    @variable(model, bounds[i,1] <= v[i=1:r] <= bounds[i,2], start=0.0) # we have d variables, setup the bounds 
    @objective(model, Min, transpose(c)*v); # set objective function, min the sum of the costs
    @constraints(model, 
        begin
            # my budget constraint
            S*v == b
        end
    );

    # run the optimization -
    optimize!(model)

    # check: was the optimization successful?
    @assert is_solved_and_feasible(model)

    # populate -
    v_opt = value.(v);
    results["argmin"] = v_opt
    results["objective_value"] = objective_value(model);

    # return -
    return results;
end
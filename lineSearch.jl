include("nonlinSolvers.jl");
using Logging;
using LinearAlgebra;
# logger = SimpleLogger(stdout, Logging.Debug);
# global_logger(logger);




# ∇f(x)
# ↦
# Rⁿ
# ∈
# dₖ
# αₖ

function generalLineSearch(f::Function, ∇f::Function, x₀=1; getSearchDirection::Function, getStepSize::Union{Real,Function,Nothing}=nothing, ϵ::Real=1e-5, maxIterations::Real=1e6, exportData::Bool = false,fileName::String="", fileDir::String="")
    @debug "inside general line search. x₀:$x₀"
    """
    General line search method.
    Essentially the update scheme is:
                    x_{k+1} = x_{k} + αₖ.dₖ,
                where dₖ is the search direction and αₖ is the step size.
    The step size could be constant, or a function of the gradient (∇f: Rⁿ↦Rⁿ).
    
    getSearchDirection : ∇f,x ↦ d: A function/mapping that takes the objective function's gradient and outputs a search direction at x. Where 'f: Rⁿ ↦ R' is the objective function  and 'd ∈ Rⁿ' is the search direction.
    getStepSize        : f,∇f,x,d ↦ α. A constant or a function/mapping that takes the objective function and its gradient, and outputs a step-size:
    """
    
    @debug "before getStepSize"
    getAlpha = NaN;

    if getStepSize == nothing
        getAlpha(f,∇f,x,d) = 1; # adjust later to make it "armijo rule"
        @debug "inside getStepSize"
        
        # else if it's not a funcion , then it's a REAl number
    elseif (typeof(getStepSize) <: Real)
        @debug "getStepSize is not a function. Making a function."
        getAlpha = (f,∇f,x,d) -> getStepSize; 
        @debug "typeof(getAlpha)<:Function: $(typeof(getAlpha)<:Function)"
    else
        @debug "Keeping the same function."
        getAlpha = getStepSize;  # assign method
    end
    
    # export to a file if the user wants
    if exportData
        if fileDir == ""
            fileDir = "data\\";
        end
        
        fileHandle = open(fileDir*"generalLineSearch_"*fileName*Dates.format(Dates.now(),"yyyymmddHHMM")*".txt","w");
        write(fileHandle,"ϵ:$ϵ\n");
        write(fileHandle,"iterations\tx\tf(x)\t∇f(x)\n");
    end
    
    # quick gradient check
    xₜ = NaN; # point to test derivative at.
    if typeof(x₀) <: Array
        xₜ = rand(length(x₀),1)*10;
    else
        xₜ = rand()*10;  
    end

    if !checkDerivative(f,∇f, x=xₜ)
        # @warn "∇f doesn't seem to be right";
        nothing;
    end
    
    n = 0; # number of maxIterations
    x = x₀;
    f_val = f(x);
    ∇f_val = ∇f(x);
    d = NaN;

    while norm(∇f_val) >= ϵ
        if exportData
            write(fileHandle,"$n\t$x\t$f\t$(∇f_val)\n"); # adjust
        end
        
        d = getSearchDirection(∇f,x);
        α = getAlpha(f,∇f,x,d);
        
        x += α*d;
        n += 1;

        f_val = f(x);
        ∇f_val = ∇f(x);

        if n == maxIterations
            @warn "Maximum iterations reached"
            @debug "n: $n. x: $x. ∇f_val: $(∇f_val). d: $d. α: $α"
            x = NaN;
            break;
        end
        
    end
    
    # checking whether the solution is close to the root or not
    if !isapprox(norm(∇f_val), 0, atol=ϵ)
        x = NaN;
    end
    
    if exportData
        write(fileHandle,"$n\t$x\t$f\t$(∇f_val)\n"); # adjust
        close(fileHandle);
    end
    return x; # adjust 
end





function gradientMethod(f::Function,∇f::Function, x₀::Union{Real,Array}; ϵ::AbstractFloat= 1e-5, maxIterations::Real=1e6,getStepSize::Union{Nothing,Real,Function}=nothing, exportData::Bool = false,fileName::String="", fileDir::String="")
    """
    This function tries to find the stationary of a function using the gradient method.
    The search direction is 
                dₖ =  -∇f(xₖ).
    The current default step length is
                α = 1.
    getStepSize: f,∇f,x,d ↦ α. A constant or a function/mapping that takes the objective function and its gradient, and outputs a step-size (could be the Armijo rule or some other method)
    """
    @debug "type of x₀: $(typeof(x₀))";
    getDirection(∇f::Function, x) = -∇f(x); # gradient method (B=I)
    
    if getStepSize == nothing
        getAlpha(f,∇f,x,d) = 1; # adjust it later to make it armijo rule
        # else if it's not a funcion , then it's a REAl number
    elseif (typeof(getStepSize) <: Real)
        getAlpha = (f,∇f,x,d) -> getStepSize; 
    else
        @debug "Keeping the same function."
        getAlpha = getStepSize;  # assign method
    end

    ans = generalLineSearch(f,∇f,x₀, getSearchDirection = getDirection, getStepSize = getAlpha, ϵ = ϵ, maxIterations = maxIterations, exportData=exportData,fileName="gradient_"*fileName,fileDir=fileDir);

    return ans;

end


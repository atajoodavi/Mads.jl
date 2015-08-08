import MPTools
include("MadsIO.jl")

@doc "Arcsine transformation of model parameters" ->
function asinetransform(params::Vector, lowerbounds::Vector, upperbounds::Vector) # asine transformation
	sineparams = asin((params - lowerbounds) ./ (upperbounds - lowerbounds) * 2 - 1) # transformed parameters (sine parameter space)
	return sineparams
end

@doc "Sine transformation of model parameters" ->
function sinetransform(sineparams::Vector, lowerbounds::Vector, upperbounds::Vector) # sine transformation
	params = lowerbounds + (upperbounds - lowerbounds) .* ((1 + sin(sineparams)) * .5) # untransformed parameters (regular parameter space)
	return params
end

@doc "Sine transformation of a function" ->
function sinetransformfunction(f::Function, lowerbounds::Vector, upperbounds::Vector) # sine transformation a function
	function sinetransformedf(sineparams::Vector)
		params = sinetransform(sineparams, lowerbounds, upperbounds)
		return f(params)
	end
	return sinetransformedf
end

@doc "Sine transformation of a gradient function" ->
function sinetransformgradient(g::Function, lowerbounds::Vector, upperbounds::Vector) # sine transformation a gradient function
	function sinetransformedg(sineparams::Vector)
		params = sinetransform(sineparams, lowerbounds, upperbounds)
		result = g(params)
		f(x) = cos(x) / 2
		transformgrad = (upperbounds - lowerbounds) .* f(sineparams)
		for i = 1:size(result, 1)
			for j = 1:size(result, 2)
				result[i, j] *= transformgrad[j]
			end
		end
		return result
	end
	return sinetransformedg
end

@doc "Make a log likelihood array" ->
function makearrayloglikelihood(madsdata, loglikelihood) # make log likelihood array
	f = makemadscommandfunction(madsdata)
	paramkeys = getparamkeys(madsdata)
	function arrayloglikelihood(arrayparameters::Vector)
		predictions = Dict()
		try
			predictions = f(Dict(paramkeys, arrayparameters))
		catch DomainError#TODO fix this so that we don't call f if the prior likelihood is zero...this is a dirty hack
			return -Inf
		end
		loglikelihood(Dict(paramkeys, arrayparameters), predictions, madsdata["Observations"])
	end
	return arrayloglikelihood
end

@doc "Set Dynamic Model for MADS model calls using internal Julia functions" ->
function setdynamicmodel(madsdata, f::Function) # TODO do we still need this
	madsdata["Dynamic model"] = f
end

@doc "Create functions to get values of the MADS parameters" ->
getparamsnames = ["init_min", "init_max", "min", "max", "init", "type", "log"]
getparamstypes = [Float64, Float64, Float64, Float64, Float64, Any, Any]
for i = 1:length(getparamsnames)
	paramname = getparamsnames[i]
	paramtype = getparamstypes[i]
	q = quote
		function $(symbol(string("getparams", paramname)))(madsdata, paramkeys) # create a function to get each parameter name with 2 arguments
			paramvalue = Array($(paramtype), length(paramkeys))
			for i in 1:length(paramkeys)
				paramvalue[i] = madsdata["Parameters"][paramkeys[i]][$paramname]
			end
			return paramvalue # returns the parameter values
		end
		function $(symbol(string("getparams", paramname)))(madsdata) # create a function to get each parameter name with 1 argument
			paramkeys = getparamkeys(madsdata) # get parameter keys
			return $(symbol(string("getparams", paramname)))(madsdata, paramkeys) # call the function with 2 arguments
		end
	end
	eval(q)
end

@doc "Create functions to get parameter keys for specific MADS parameters (optimized and log-transformed)" ->
getfunction = [getparamstype, getparamslog]
keywordname = ["opt", "log"]
keywordvals = ["opt", true]
for i = 1:length(getfunction)
	q = quote
		function $(symbol(string("get", keywordname[i], "paramkeys")))(madsdata, paramkeys) # create functions getoptparamkeys / getlogparamkeys
			paramtypes = $(getfunction[i])(madsdata, paramkeys)
			return paramkeys[paramtypes .== $(keywordvals[i])]
		end
		function $(symbol(string("get", keywordname[i], "paramkeys")))(madsdata)
			paramkeys = getparamkeys(madsdata)
			return $(symbol(string("get", keywordname[i], "paramkeys")))(madsdata, paramkeys)
		end
		function $(symbol(string("getnon", keywordname[i], "paramkeys")))(madsdata, paramkeys) # create functions getnonoptparamkeys / getnonlogparamkeys
			paramtypes = $(getfunction[i])(madsdata, paramkeys)
			return paramkeys[paramtypes .!= $(keywordvals[i])]
		end
		function $(symbol(string("getnon", keywordname[i], "paramkeys")))(madsdata)
			paramkeys = getparamkeys(madsdata)
			return $(symbol(string("getnon", keywordname[i], "paramkeys")))(madsdata, paramkeys)
		end
	end
	eval(q)
end

@doc "Get keys for optimized parameters (redundant; already created above)" ->
function getoptparamkeys(madsdata)
	paramtypes = getparamstype(madsdata)
	paramkeys = getparamkeys(madsdata)
	return paramkeys[paramtypes .== "opt"]
end

@doc "Evaluate the expression in terms of the parameters, return a Dict() containing the expression names as keys, and the values of the expression as values" ->
function evaluatemadsexpression(expressionstring, parameters)
	expression = parse(expressionstring)
	MPTools.populateexpression!(expression, parameters)
	retval::Float64
	retval = eval(expression) # populate the expression with the parameter values, then evaluate it
	return retval
end

@doc "Evaluate the expressions in terms of the parameters, return a Dict() containing the expression names as keys, and the values of the expression as values" ->
function evaluatemadsexpressions(parameters, madsdata)
	if haskey(madsdata, "Expressions")
		expressions = Dict()
		for exprname in keys(madsdata["Expressions"])
			expressions[exprname] = evaluatemadsexpression(madsdata["Expressions"][exprname]["exp"], parameters)
		end
		return expressions
	else
		return Dict()
	end
end
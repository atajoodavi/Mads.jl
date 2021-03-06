import DataStructures

function madsmodelrun_internal_linearmodel_template(madsdata::Associative) # mads data dictionary is as an argument if needed
	# Replace with:
	# - a system call executing an external model
	# - a parser of the model outputs
	# - return a dictionary with model predictions
	i = open("parameters.dat", "r")
	param = readdlm(i)
	close(i)
	a = param[1]
	b = param[2]
	f(t) = a * t - b # a * t - b
	times = 1:4
	predictions = DataStructures.OrderedDict{String, Float64}(zip(map(i -> string("o", i), times), map(f, times)))
	return predictions
end

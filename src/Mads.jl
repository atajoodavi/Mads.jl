# __precompile__()

"""
MADS: Model Analysis & Decision Support in Julia (Mads.jl v1.0) 2016

http://mads.lanl.gov
https://github.com/madsjulia

Licensing: GPLv3: http://www.gnu.org/licenses/gpl-3.0.html
"""
module Mads

import JLD
import YAML
import JSON

import Anasol
import BIGUQ
import AffineInvariantMCMC
import GeostatInversion
import Kriging
import MetaProgTools
import ReusableFunctions
import RobustPmap
import SVR
import DocumentFunction

global madsgit = true
try
	run(pipeline(`git help`, stdout=DevNull, stderr=DevNull))
catch
	global madsgit = false
end

global madsbash = true
if !Sys.is_windows()
	try
		run(pipeline(`bash --help`, stdout=DevNull, stderr=DevNull))
	catch
		global madsbash = false
	end
end

"""
Mads Modules: $madsmodules
"""
global madsmodules = ["Mads", "Anasol", "AffineInvariantMCMC", "GeostatInversion", "Kriging", "BIGUQ", "ReusableFunctions", "RobustPmap", "MetaProgTools", "SVR", "DocumentFunction"]

include("MadsHelpers.jl")

"Try to import a module"
macro tryimport(s::Symbol)
	mname = string(s)
	importq = string(:(import $s))
	infostring = string("Module ", s, " is not available")
	warnstring = string("Module ", s, " cannot be imported")
	q = quote
		if Mads.ispkgavailable($mname; quiet=true)
			try
				eval(parse($importq))
			catch errmsg
				Mads.printerrormsg(errmsg)
				warn($warnstring)
			end
		else
			info($infostring)
		end
	end
	return :($(esc(q)))
end

if !haskey(ENV, "MADS_NO_PYTHON")
	@tryimport PyCall
	if isdefined(:PyCall)
		try
			eval(:(@PyCall.pyimport yaml))
		catch
			ENV["PYTHON"] = ""
			warn("PyYAML is not available (in the available python installation)")
		end
		if !isdefined(Mads, :yaml)
			if haskey(ENV, "PYTHON") && ENV["PYTHON"] == ""
				@tryimport Conda
			end
			pyyamlok = false
			try
				eval(:(@PyCall.pyimport yaml))
				pyyamlok = true
			catch
				warn("PyYAML is not available (in Conda)")
			end
			if pyyamlok
				eval(:(@PyCall.pyimport yaml))
			end
		end
	else
		ENV["MADS_NO_PYTHON"] = ""
	end
end

global vectorflag = false
global quiet = true
global restart = false
global graphoutput = true
global graphbackend = "SVG"
global dpi=300
global verbositylevel = 1
global debuglevel = 1
global modelruns = 0
global madsinputfile = ""
global executionwaittime = 0.0
global sindxdefault = 0.1
global create_tests = false # dangerous if true
global long_tests = false # execute long tests
global madsservers = ["madsmax", "madsmen", "madsdam", "madszem", "madskil", "madsart", "madsend"]
global madsservers2 = ["madsmin"; map(i->(@sprintf "mads%02d" i), 1:18); "es05"; "es06"]
global nprocs_per_task_default = 1
const madsdir = splitdir(Base.source_path())[1]

if haskey(ENV, "MADS_LONG_TESTS")
	global long_tests = true
end

if haskey(ENV, "MADS_QUIET")
	global quiet = true
end

if haskey(ENV, "MADS_NOT_QUIET")
	global quiet = false
end

include("MadsCapture.jl")
include("MadsLog.jl")
include("MadsHelp.jl")
include("MadsCreate.jl")
include("MadsIO.jl")
include("MadsYAML.jl")
include("MadsASCII.jl")
include("MadsJSON.jl")
include("MadsSineTransformations.jl")
include("MadsMisc.jl")
include("MadsParameters.jl")
include("MadsObservations.jl")
include("MadsForward.jl")
include("MadsFunc.jl")
include("MadsExecute.jl")
include("MadsCalibrate.jl")
include("MadsMinimization.jl")
include("MadsLevenbergMarquardt.jl")
include("MadsMonteCarlo.jl")
include("MadsKriging.jl")
include("MadsBayesInfoGap.jl")
include("MadsModelSelection.jl")
include("MadsAnasol.jl")
include("MadsTestFunctions.jl")
include("MadsSVR.jl")

if Mads.pkgversion("Gadfly") == v"0.6.1"
	ENV["MADS_NO_GADFLY"] = ""
	warn("Gadfly v0.6.1 has bugs; update or downgrade to another version!")
	warn("Gadfly plotting is disabled!")
end

if !haskey(ENV, "MADS_NO_PLOT")
	if !haskey(ENV, "MADS_NO_GADFLY")
		@Mads.tryimport Gadfly
		if !isdefined(:Gadfly)
			ENV["MADS_NO_GADFLY"] = ""
		end
	end
	if !haskey(ENV, "MADS_NO_PYTHON") && !haskey(ENV, "MADS_NO_PYPLOT")
		@Mads.tryimport PyCall
		@Mads.tryimport PyPlot
		if !isdefined(:PyPlot)
			ENV["MADS_NO_PYPLOT"] = ""
		end
	end
else
	ENV["MADS_NO_GADFLY"] = ""
	ENV["MADS_NO_PYPLOT"] = ""
	ENV["MADS_NO_DISPLAY"] = ""
	global graphoutput = false
	warn("Mads plotting is disabled")
end

if haskey(ENV, "MADS_TRAVIS")
	global graphoutput = false
else
	include(joinpath("..", "src-interactive", "MadsPublish.jl"))
	include(joinpath("..", "src-interactive", "MadsParallel.jl"))
	include(joinpath("..", "src-interactive", "MadsTest.jl"))
	if !haskey(ENV, "MADS_NO_DISPLAY")
		include(joinpath("..", "src-interactive", "MadsDisplay.jl"))
	end
	include(joinpath("..", "src-external", "MadsSimulators.jl"))
	include(joinpath("..", "src-external", "MadsParsers.jl"))
	include(joinpath("..", "src-old", "MadsCMads.jl"))
	@Mads.tryimport JuMP
	if isdefined(:JuMP)
		include(joinpath("..", "src-new", "MadsInfoGap.jl"))
		include(joinpath("..", "src-new", "MadsBSS.jl"))
		include(joinpath("..", "src-new", "MadsMathProgBase.jl"))
	end
end

include("MadsSenstivityAnalysis.jl")

if !haskey(ENV, "MADS_NO_GADFLY")
	include("MadsAnasolPlot.jl")
	include("MadsBayesInfoGapPlot.jl")
	include("MadsPlot.jl")
end

if !haskey(ENV, "MADS_NO_PYTHON") && !haskey(ENV, "MADS_NO_PYPLOT")
	include("MadsPlotPy.jl")
end

end

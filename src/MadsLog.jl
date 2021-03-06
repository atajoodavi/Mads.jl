import DocumentFunction

"""
MADS output (controlled by `quiet` and `verbositylevel`)

$(DocumentFunction.documentfunction(madsoutput;
argtext=Dict("message"=>"output message",
            "level"=>"output verbosity level [default=`0`]")))
"""
function madsoutput(message::AbstractString, level::Int=0)
	if !quiet && level < verbositylevel
		print(Base.STDERR, message)
		flush(Base.STDOUT)
		flush(Base.STDERR)
	end
end

"""
MADS debug messages (controlled by `quiet` and `debuglevel`)

$(DocumentFunction.documentfunction(madsdebug;
argtext=Dict("message"=>"debug message",
            "level"=>"output verbosity level [default=`0`]")))
"""
function madsdebug(message::AbstractString, level::Int=0)
	if !quiet && level < debuglevel
		print_with_color(:green, Base.STDERR, "DEBUG: " * Libc.strftime("%Y-%m-%d %H:%M:%S", time()) * " " * message * "\n")
		flush(Base.STDOUT)
		flush(Base.STDERR)
	end
end

"""
MADS information/status messages (controlled by quiet` and `verbositylevel`)

$(DocumentFunction.documentfunction(madsinfo;
argtext=Dict("message"=>"information/status message",
            "level"=>"output verbosity level [default=`0`]")))
"""
function madsinfo(message::AbstractString, level::Int=0)
	if !quiet && level < verbositylevel
		info(Libc.strftime("%Y-%m-%d %H:%M:%S", time()) * " " * message); flush(Base.STDOUT); flush(Base.STDERR)
	end
end

"""
MADS warning messages

$(DocumentFunction.documentfunction(madswarn;
argtext=Dict("message"=>"warning message")))
"""
function madswarn(message::AbstractString)
	warn(Libc.strftime("%Y-%m-%d %H:%M:%S", time()) * " " * message  * "\n"); flush(Base.STDOUT); flush(Base.STDERR)
end

"""
MADS error messages

$(DocumentFunction.documentfunction(madserror;
argtext=Dict("message"=>"error message")))
"""
function madserror(message::AbstractString)
	error(Libc.strftime("%Y-%m-%d %H:%M:%S", time()) * " " * message); flush(Base.STDOUT); flush(Base.STDERR)
end

"""
MADS critical error messages

$(DocumentFunction.documentfunction(madscritical;
argtext=Dict("message"=>"critical error message")))
"""
function madscritical(message::AbstractString)
	madserror(message); throw("Mads quits!")
end

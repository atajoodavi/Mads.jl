if !haskey(ENV, "MADS_NO_GADFLY")
	@Mads.tryimport Gadfly
end
@Mads.tryimport Images

function display(filename::String)
	if !isfile(filename)
		warn("File `$filename` is missing!")
		return
	end
	if isdefined(:TerminalExtensions) || isdefined(:IJulia)
		trytoopen = false
		ext = lowercase(Mads.getextension(filename))
		if ext == "svg"
			root = Mads.getrootname(filename)
			filename2 = root * ".png"
			try
				run(`convert -density 90 -background none $filename $filename2`)
				img = Images.load(filename2)
				Base.display(img)
				println("")
			catch
				trytoopen = true
			end
			if isfile(filename2)
				rm(filename2)
			end
		else
			try
				img = Images.load(filename)
				Base.display(img)
				println("")
			catch
				trytoopen = true
			end
		end
	else
		trytoopen = true
	end
	if trytoopen
		try
			run(`open $filename`)
		catch
			try
				run(`xdg-open $filename`)
			catch
				warn("Do not know how to open `$filename`")
			end
		end
	end
end

if isdefined(:Gadfly)
	function display(p::Gadfly.Plot)
		Base.display(p)
		println()
	end
end

@doc """
Display image file

$(DocumentFunction.documentfunction(display;
argtext=Dict("filename"=>"image file name")))
""" display
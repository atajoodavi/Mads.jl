import Mads
import JLD
import Base.Test

Mads.madsinfo("Bayesian sampling ...")

workdir = Mads.getmadsdir() # get the directory where the problem is executed
if workdir == "."
	workdir = joinpath(Mads.madsdir, "..", "examples", "bayesian_sampling")
end

md = Mads.loadmadsfile(joinpath(workdir, "internal-linearmodel.mads"))
rootname = Mads.getmadsrootname(md)

mcmcchains_emcee = Mads.emceesampling(md; numwalkers=2, nsteps=10, burnin=2, thinning=2, seed=2016)

if isdefined(Klara, :BasicContMuvParameter)
	Mads.bayessampling(md, 1; nsteps=1, burnin=1, thinning=1)
	mcmcchains_bayes = Mads.bayessampling(md, 2; nsteps=10, burnin=1, thinning=1, seed=2016)
	mcmcchain = Mads.bayessampling(md; nsteps=10, burnin=1, thinning=1, seed=2016)
	Mads.savemcmcresults(mcmcchain.value', rootname * "-test-mcmcchain1.json")
	rm(rootname * "-test-mcmcchain1.json")
	Mads.forward(md, mcmcchain.value; all=true)
end

md = Mads.loadmadsfile(joinpath(workdir, "w01.mads"))
rootname = Mads.getmadsrootname(md)
if isdefined(Klara, :BasicContMuvParameter)
	mcmcchain = Mads.bayessampling(md; nsteps=10, burnin=1, thinning=1, seed=2016)
	mcmcvalues = Mads.paramarray2dict(md, mcmcchain.value') # convert the parameters in the chain to a parameter dictionary of arrays
	mcmcvalues_array = hcat(vcat(map(i->collect(mcmcvalues[i]), keys(mcmcvalues)))...)
	Mads.forward(md, mcmcchain.value)
	if isdefined(:Gadfly) && !haskey(ENV, "MADS_NO_GADFLY")
		Mads.scatterplotsamples(md, mcmcchain.value', rootname * "-test-bayes-results.svg")
		Mads.rmfile(rootname * "-test-bayes-results.svg")
		Mads.spaghettiplots(md, mcmcvalues; keyword="", obs_plot_dots=false)
		Mads.spaghettiplot(md, mcmcvalues; keyword="test")
		Mads.spaghettiplots(md, 3; keyword="test", grayscale=true)
		Mads.spaghettiplot(md, 3; keyword="test", grayscale=true)
		s = splitdir(rootname)
		for filesinadir in Mads.searchdir(Regex(string(s[2], "-", "\.*", "spaghetti.svg")), path=s[1])
			Mads.rmfile(filesinadir, path=s[1])
		end
	end
end

if Mads.create_tests
	d = joinpath(workdir, "test_results")
	Mads.mkdir(d)

	JLD.save(joinpath(d, "mcmcchains_emcee.jld"), "mcmcchains_emcee", mcmcchains_emcee)
	JLD.save(joinpath(d, "mcmcvalues.jld"), "mcmcvalues", mcmcvalues)
end

good_mcmcvalues = JLD.load(joinpath(workdir, "test_results", "mcmcvalues.jld"), "mcmcvalues")
good_mcmcvalues_array = hcat(vcat(map(i->collect(good_mcmcvalues[i]), keys(good_mcmcvalues)))...)

good_mcmcchains_emcee = JLD.load(joinpath(workdir, "test_results", "mcmcchains_emcee.jld"), "mcmcchains_emcee")

@Base.Test.testset "Bayesian" begin
	@Base.Test.testset "bayes" begin
		isdefined(:mcmcvalues_array) && @Base.Test.test isapprox(good_mcmcvalues_array, mcmcvalues_array, atol=1e-8)
	end
	@Base.Test.testset "emcee" begin
		@Base.Test.test good_mcmcchains_emcee == mcmcchains_emcee
	end

end

Mads.rmdir(joinpath(workdir, "..", "model_coupling", "internal-linearmodel_restart"))
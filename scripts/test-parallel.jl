include(joinpath(Pkg.dir("Mads"), "src", "MadsParallel.jl"))
info("Set processors ...")
setprocs(ntasks_per_node=1)

info("Import MADS ...")
import Mads
@everywhere Mads.quietoff()

info("Test MADS ... ")
Mads.test()

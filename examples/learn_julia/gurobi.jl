# import Gadfly
import JuMP
import Gurobi

m = JuMP.Model(solver=Gurobi.GurobiSolver(Threads=4))
@JuMP.variables m begin
	Pennies >=0, Int
	Nickels >=0, Int
	Dimes >=0, Int
	Quarters >=0, Int
	Dollars >=0, Int
	0 <= Cu <= 1000
	0 <= Ni <= 50
	0 <= Zi <= 50
	0 <= Mn <= 50
end
@JuMP.constraints m begin
	Copper, .06Pennies + 3.8Nickels + 2.1Dimes + 5.2Quarters +7.2Dollars - Cu == 0
	Nickel, 1.2Nickels + .2Dimes + .5Quarters + .2Dollars - Ni == 0
	Zinc, 2.4Pennies +.5Dollars - Zi == 0
	Manganese, .3Dollars - Mn == 0
end
@JuMP.objective(m, Max, .01Pennies + .05Nickels + .1Dimes + .25Quarters + 1Dollars )
status=JuMP.solve(m)
println("Status = $status")
println("Optimal Objective Function value: ", JuMP.getobjectivevalue(m))
println("Optimal Solutions:")
println("Pennies = ", JuMP.getvalue(Pennies))
println("Nickels = ", JuMP.getvalue(Nickels))
println("Dimes = ", JuMP.getvalue(Dimes))
println("Quarters = ", JuMP.getvalue(Quarters))
println("Dollars = ", JuMP.getvalue(Dollars))
println("Cu = ", JuMP.getvalue(Cu))
println("Ni = ", JuMP.getvalue(Ni))
println("Zi = ", JuMP.getvalue(Zi))
println("Mn = ", JuMP.getvalue(Mn))

m2 = JuMP.Model(solver=Gurobi.GurobiSolver(Threads=4))
@JuMP.variable(m2, x >=0)
@JuMP.variable(m2, y >=0)
@JuMP.objective(m2, Min, 10x + 26y)
@JuMP.constraint(m2, const1, 11x +  3y >= 21)
@JuMP.constraint(m2, const2,  6x + 20y >= 39)
status = JuMP.solve(m2)
println("Status = $status")
println("Optimal Objective Function value: ", JuMP.getobjectivevalue(m2))
println("Optimal Solutions:")
println("x = ", JuMP.getvalue(x))
println("y = ", JuMP.getvalue(y))
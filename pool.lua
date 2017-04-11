local mod = {}

function mod.newpop()
    local pop = {}
    pop.species = {}
    pop.generation = 0
    pop.innovation = Outputs
    pop.currentSpecies = 1
    pop.currentGenome = 1
    pop.currentFrame = 0
    pop.maxFitness = 0
    return pop
end

function mod.newInnovation(pop)
	pop.innovation = pop.innovation + 1
	return pop.innovation
end

function mod.totalAverageFitness(pop)
	local total = 0
	for s = 1,#pop.species do
		local species = pop.species[s]
		total = total + species.averageFitness
	end

	return total
end

function mod.cullSpecies(cutToOne,pop)
	for s = 1,#pop.species do
		local species = pop.species[s]

		table.sort(species.genomes, function (a,b)
			return (a.fitness > b.fitness)
		end)

		local remaining = math.ceil(#species.genomes/2)
		if cutToOne then
			remaining = 1
		end
		while #species.genomes > remaining do
			table.remove(species.genomes)
		end
	end
end

function mod.removeStaleSpecies(pop)
	local survived = {}

	for s = 1,#pop.species do
		local species = pop.species[s]

		table.sort(species.genomes, function (a,b)
			return (a.fitness > b.fitness)
		end)
		
		if species.genomes[1].fitness > species.topFitness then
			species.topFitness = species.genomes[1].fitness
			species.staleness = 0
		else
			species.staleness = species.staleness + 1
		end
		if species.staleness < StaleSpecies or species.topFitness >= pop.maxFitness then
			table.insert(survived, species)
		end
	end

	pop.species = survived
end

function mod.removeWeakSpecies(pop)
	local survived = {}

	local sum = totalAverageFitness()
	for s = 1,#pop.species do
		local species = pop.species[s]
		breed = math.floor(species.averageFitness / sum * Population)
		if breed >= 1 then
			table.insert(survived, species)
		end
	end

	pop.species = survived
end

function mod.addToSpecies(child,pop)
	local foundSpecies = false
	for s=1,#pop.species do
		local species = pop.species[s]
		if not foundSpecies and sameSpecies(child, species.genomes[1]) then
			table.insert(species.genomes, child)
			foundSpecies = true
		end
	end
	if not foundSpecies then
		local childSpecies = newSpecies()
		table.insert(childSpecies.genomes, child)
		table.insert(pop.species, childSpecies)
	end
end

function mod.nextGenome(pop)
	pop.currentGenome = pop.currentGenome + 1
	if pop.currentGenome > #pop.species[pop.currentSpecies].genomes then
		pop.currentGenome = 1
		pop.currentSpecies = pop.currentSpecies+1
		if pop.currentSpecies > #pop.species then
			newGeneration()
			pop.currentSpecies = 1
		end
	end
end

return mod
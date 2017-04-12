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

function mod.newInnovation()
	pool.innovation = pool.innovation + 1
	return pool.innovation
end

function mod.totalAverageFitness()
	local total = 0
	for s = 1,#pool.species do
		local species = pool.species[s]
		total = total + species.averageFitness
	end

	return total
end

function mod.cullSpecies(cutToOne)
	for s = 1,#pool.species do
		local species = pool.species[s]

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

function mod.removeStaleSpecies()
	local survived = {}

	for s = 1,#pool.species do
		local species = pool.species[s]

		table.sort(species.genomes, function (a,b)
			return (a.fitness > b.fitness)
		end)
		
		if species.genomes[1].fitness > species.topFitness then
			species.topFitness = species.genomes[1].fitness
			species.staleness = 0
		else
			species.staleness = species.staleness + 1
		end
		if species.staleness < StaleSpecies or species.topFitness >= pool.maxFitness then
			table.insert(survived, species)
		end
	end

	pool.species = survived
end

function mod.removeWeakSpecies()
	local survived = {}

	local sum = mod.totalAverageFitness()
	for s = 1,#pool.species do
		local species = pool.species[s]
		breed = math.floor(species.averageFitness / sum * Population)
		if breed >= 1 then
			table.insert(survived, species)
		end
	end

	pool.species = survived
end

function mod.addToSpecies(child)
	local foundSpecies = false
	for s=1,#pool.species do
		local species = pool.species[s]
		if not foundSpecies and ggenome.sameSpecies(child, species.genomes[1]) then
			table.insert(species.genomes, child)
			foundSpecies = true
		end
	end
	if not foundSpecies then
		local childSpecies = gspecies.newSpecies()
		table.insert(childSpecies.genomes, child)
		table.insert(pool.species, childSpecies)
	end
end

function mod.rankGlobally()
	local global = {}
	for s = 1,#pool.species do
		local species = pool.species[s]
		for g = 1,#species.genomes do
			table.insert(global, species.genomes[g])
		end
	end
	table.sort(global, function (a,b)
		return (a.fitness < b.fitness)
	end)
	
	for g=1,#global do
		global[g].globalRank = g
	end
end

return mod
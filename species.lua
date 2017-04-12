local mod = {}

function mod.newSpecies()
    local species = {}
    species.topFitness = 0
    species.staleness = 0
    species.genomes = {}
    species.averageFitness = 0
    return species
end

function mod.calculateAverageFitness(species)
	local total = 0
	
	for g=1,#species.genomes do
		local genome = species.genomes[g]
		total = total + genome.globalRank
	end
	
	species.averageFitness = total / #species.genomes
end

function mod.breedChild(species)
	local child = {}
	if math.random() < CrossoverChance then
		g1 = species.genomes[math.random(1, #species.genomes)]
		g2 = species.genomes[math.random(1, #species.genomes)]
		child = ggenome.crossover(g1, g2)
	else
		g = species.genomes[math.random(1, #species.genomes)]
		child = ggenome.copyGenome(g)
	end

	ggenome.mutate(child)
	return child
end

return mod
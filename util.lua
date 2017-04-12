local mod = {}

function mod.clearJoypad()
	controller = {}
	for b = 1,#ButtonNames do
		controller["P1 " .. ButtonNames[b]] = false
	end
	joypad.set(controller)
end

function mod.savePool()
	local filename = forms.gettext(saveLoadFile)
	mod.writeFile(filename)
end

function mod.loadPool()
	local filename = forms.gettext(saveLoadFile)
	mod.loadFile(filename)
end

function mod.fitnessAlreadyMeasured()
	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]
	return genome.fitness ~= 0
end

function mod.sigmoid(x)
	return 2/(1+math.exp(-4.9*x))-1
end

function mod.generateNetwork(genome)
    local network = {}
    network.neurons = {}

    for i=1,Inputs do
        network.neurons[i] = gneuron.newNeuron()
    end

    for o=1,Outputs do
        network.neurons[MaxNodes+o] = gneuron.newNeuron()
    end

    table.sort(genome.genes, function (a,b)
        return (a.out < b.out)
    end)
    for i=1,#genome.genes do
        local gene = genome.genes[i]
        if gene.enabled then
            if network.neurons[gene.out] == nil then
                network.neurons[gene.out] = gneuron.newNeuron()
            end
            local neuron = network.neurons[gene.out]
            table.insert(neuron.incoming, gene)
            if network.neurons[gene.into] == nil then
                network.neurons[gene.into] = gneuron.newNeuron()
            end
        end
    end
    genome.network = network
end

function mod.evaluateNetwork(network, inputs)
	table.insert(inputs, 1)
	if #inputs ~= Inputs then
		console.writeline("Incorrect number of neural network inputs.")
		return {}
	end

	for i=1,Inputs do
		network.neurons[i].value = inputs[i]
	end

	for _,neuron in pairs(network.neurons) do
		local sum = 0
		for j = 1,#neuron.incoming do
			local incoming = neuron.incoming[j]
			local other = network.neurons[incoming.into]
			sum = sum + incoming.weight * other.value
		end

		if #neuron.incoming > 0 then
			neuron.value = mod.sigmoid(sum)
		end
	end

	local outputs = {}
	for o=1,Outputs do
		local button = "P1 " .. ButtonNames[o]
		if network.neurons[MaxNodes+o].value > 0 then
			outputs[button] = true
		else
			outputs[button] = false
		end
	end

	return outputs
end

function mod.evaluateCurrent()
	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]

	inputs = game.getInputs()
	controller = mod.evaluateNetwork(genome.network, inputs)
	
	if controller["P1 Left"] and controller["P1 Right"] then
		controller["P1 Left"] = false
		controller["P1 Right"] = false
	end
	if controller["P1 Up"] and controller["P1 Down"] then
		controller["P1 Up"] = false
		controller["P1 Down"] = false
	end

	joypad.set(controller)
end

function mod.initializeRun()
	savestate.load(Filename);
	rightmost = 0
	pool.currentFrame = 0
	timeout = TimeoutConstant
	mod.clearJoypad()

	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]
	mod.generateNetwork(genome)
	mod.evaluateCurrent()
end

function mod.initializePool()
	pool = gpool.newpop()

	for i=1,Population do
		basic = ggenome.basicGenome()
		gpool.addToSpecies(basic)
	end

	mod.initializeRun()
end

function mod.newGeneration()
	gpool.cullSpecies(false) -- Cull the bottom half of each species
	gpool.rankGlobally()
	gpool.removeStaleSpecies()
	gpool.rankGlobally()
	for s = 1,#pool.species do
		local species = pool.species[s]
		gspecies.calculateAverageFitness(species)
	end
	gpool.removeWeakSpecies()
	local sum = gpool.totalAverageFitness()
	local children = {}
	for s = 1,#pool.species do
		local species = pool.species[s]
		breed = math.floor(species.averageFitness / sum * Population) - 1
		for i=1,breed do
			table.insert(children, gspecies.breedChild(species))
		end
	end
	gpool.cullSpecies(true) -- Cull all but the top member of each species
	while #children + #pool.species < Population do
		local species = pool.species[math.random(1, #pool.species)]
		table.insert(children, gspecies.breedChild(species))
	end
	for c=1,#children do
		local child = children[c]
		gpool.addToSpecies(child,pool)
	end
	pool.generation = pool.generation + 1
	mod.writeFile("backup." .. pool.generation .. "." .. forms.gettext(saveLoadFile))
end

function mod.nextGenome()
	pool.currentGenome = pool.currentGenome + 1
	if pool.currentGenome > #pool.species[pool.currentSpecies].genomes then
		pool.currentGenome = 1
		pool.currentSpecies = pool.currentSpecies+1
		if pool.currentSpecies > #pool.species then
			mod.newGeneration()
			pool.currentSpecies = 1
		end
	end
end

function mod.writeFile(filename)
    local file = io.open(filename, "w")
	file:write(pool.generation .. "\n")
	file:write(pool.maxFitness .. "\n")
	file:write(#pool.species .. "\n")
        for n,species in pairs(pool.species) do
		file:write(species.topFitness .. "\n")
		file:write(species.staleness .. "\n")
		file:write(#species.genomes .. "\n")
		for m,genome in pairs(species.genomes) do
			file:write(genome.fitness .. "\n")
			file:write(genome.maxneuron .. "\n")
			for mutation,rate in pairs(genome.mutationRates) do
				file:write(mutation .. "\n")
				file:write(rate .. "\n")
			end
			file:write("done\n")
			
			file:write(#genome.genes .. "\n")
			for l,gene in pairs(genome.genes) do
				file:write(gene.into .. " ")
				file:write(gene.out .. " ")
				file:write(gene.weight .. " ")
				file:write(gene.innovation .. " ")
				if(gene.enabled) then
					file:write("1\n")
				else
					file:write("0\n")
				end
			end
		end
        end
        file:close()
end

function mod.loadFile(filename)
    local file = io.open(filename, "r")
	pool = gpool.newpop()
	pool.generation = file:read("*number")
	pool.maxFitness = file:read("*number")
	forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(pool.maxFitness))
        local numSpecies = file:read("*number")
        for s=1,numSpecies do
		local species = gspecies.newSpecies()
		table.insert(pool.species, species)
		species.topFitness = file:read("*number")
		species.staleness = file:read("*number")
		local numGenomes = file:read("*number")
		for g=1,numGenomes do
			local genome = ggenome.newGenome()
			table.insert(species.genomes, genome)
			genome.fitness = file:read("*number")
			genome.maxneuron = file:read("*number")
			local line = file:read("*line")
			while line ~= "done" do
				genome.mutationRates[line] = file:read("*number")
				line = file:read("*line")
			end
			local numGenes = file:read("*number")
			for n=1,numGenes do
				local gene = ggene.newGene()
				table.insert(genome.genes, gene)
				local enabled
				gene.into, gene.out, gene.weight, gene.innovation, enabled = file:read("*number", "*number", "*number", "*number", "*number")
				if enabled == 0 then
					gene.enabled = false
				else
					gene.enabled = true
				end
			end
		end
	end
    file:close()

	while mod.fitnessAlreadyMeasured() do
		mod.nextGenome()
	end
	mod.initializeRun()
	pool.currentFrame = pool.currentFrame + 1
end

return mod
ggene = require "gene"
gneuron = require "neuron"
local mod = {}

function mod.newGenome()
    local genome = {}
    genome.genes = {}
    genome.fitness = 0
    genome.adjustedFitness = 0
    genome.network = {}
    genome.maxneuron = 0
    genome.globalRank = 0
    genome.mutationRates = {}
    genome.mutationRates["connections"] = MutateConnectionsChance
    genome.mutationRates["link"] = LinkMutationChance
    genome.mutationRates["bias"] = BiasMutationChance
    genome.mutationRates["node"] = NodeMutationChance
    genome.mutationRates["enable"] = EnableMutationChance
    genome.mutationRates["disable"] = DisableMutationChance
    genome.mutationRates["step"] = StepSize
    return genome
end

function mod.copyGenome(genome)
    local genome2 = newGenome()
    for g=1,#genome.genes do
        table.insert(genome2.genes, gene.copyGene(genome.genes[g]))
    end
    genome2.maxneuron = genome.maxneuron
    genome2.mutationRates["connections"] = genome.mutationRates["connections"]
    genome2.mutationRates["link"] = genome.mutationRates["link"]
    genome2.mutationRates["bias"] = genome.mutationRates["bias"]
    genome2.mutationRates["node"] = genome.mutationRates["node"]
    genome2.mutationRates["enable"] = genome.mutationRates["enable"]
    genome2.mutationRates["disable"] = genome.mutationRates["disable"]

    return genome2
end

function mod.basicGenome()
    local genome = mod.newGenome()
    local innovation = 1

    genome.maxneuron = Inputs
    mod.mutate(genome)

    return genome
end

function mod.crossover(g1, g2)
    -- Make sure g1 is the higher fitness genome
    if g2.fitness > g1.fitness then
        tempg = g1
        g1 = g2
        g2 = tempg
    end

    local child = mod.newGenome()

    local innovations2 = {}
    for i=1,#g2.genes do
        local gene = g2.genes[i]
        innovations2[gene.innovation] = gene
    end

    for i=1,#g1.genes do
        local gene1 = g1.genes[i]
        local gene2 = innovations2[gene1.innovation]
        if gene2 ~= nil and math.random(2) == 1 and gene2.enabled then
            table.insert(child.genes, ggene.copyGene(gene2))
        else
            table.insert(child.genes, ggene.copyGene(gene1))
        end
    end

    child.maxneuron = math.max(g1.maxneuron,g2.maxneuron)

    for mutation,rate in pairs(g1.mutationRates) do
        child.mutationRates[mutation] = rate
    end

    return child
end

function mod.pointMutate(genome)
    local step = genome.mutationRates["step"]

    for i=1,#genome.genes do
        local gene = genome.genes[i]
        if math.random() < PerturbChance then
            gene.weight = gene.weight + math.random() * step*2 - step
        else
            gene.weight = math.random()*4-2
        end
    end
end

function mod.linkMutate(genome, forceBias)
    local neuron1 = gneuron.randomNeuron(genome.genes, false)
    local neuron2 = gneuron.randomNeuron(genome.genes, true)

    local newLink = ggene.newGene()
    if neuron1 <= Inputs and neuron2 <= Inputs then
        --Both input nodes
        return
    end
    if neuron2 <= Inputs then
        -- Swap output and input
        local temp = neuron1
        neuron1 = neuron2
        neuron2 = temp
    end

    newLink.into = neuron1
    newLink.out = neuron2
    if forceBias then
        newLink.into = Inputs
    end

    if containsLink(genome.genes, newLink) then
        return
    end
    newLink.innovation = newInnovation()
    newLink.weight = math.random()*4-2
    
    table.insert(genome.genes, newLink)
end

function mod.nodeMutate(genome,pop)
    if #genome.genes == 0 then
        return
    end

    genome.maxneuron = genome.maxneuron + 1

    local gene = genome.genes[math.random(1,#genome.genes)]
    if not gene.enabled then
        return
    end
    gene.enabled = false

    local gene1 = ggene.copyGene(gene)
    gene1.out = genome.maxneuron
    gene1.weight = 1.0
    gene1.innovation = pop.newInnovation()
    gene1.enabled = true
    table.insert(genome.genes, gene1)

    local gene2 = ggene.copyGene(gene)
    gene2.into = genome.maxneuron
    gene2.innovation = pop.newInnovation()
    gene2.enabled = true
    table.insert(genome.genes, gene2)
end

function mod.enableDisableMutate(genome, enable)
    local candidates = {}
    for _,gene in pairs(genome.genes) do
        if gene.enabled == not enable then
            table.insert(candidates, gene)
        end
    end
    
    if #candidates == 0 then
        return
    end
    
    local gene = candidates[math.random(1,#candidates)]
    gene.enabled = not gene.enabled
end

function mod.mutate(genome)
    for mutation,rate in pairs(genome.mutationRates) do
        if math.random(1,2) == 1 then
            genome.mutationRates[mutation] = 0.95*rate
        else
            genome.mutationRates[mutation] = 1.05263*rate
        end
    end

    if math.random() < genome.mutationRates["connections"] then
        mod.pointMutate(genome)
    end
    
    local p = genome.mutationRates["link"]
    while p > 0 do
        if math.random() < p then
            mod.linkMutate(genome, false)
        end
        p = p - 1
    end

    p = genome.mutationRates["bias"]
    while p > 0 do
        if math.random() < p then
            mod.linkMutate(genome, true)
        end
        p = p - 1
    end
    
    p = genome.mutationRates["node"]
    while p > 0 do
        if math.random() < p then
            mod.nodeMutate(genome)
        end
        p = p - 1
    end
    
    p = genome.mutationRates["enable"]
    while p > 0 do
        if math.random() < p then
            mod.enableDisableMutate(genome, true)
        end
        p = p - 1
    end

    p = genome.mutationRates["disable"]
    while p > 0 do
        if math.random() < p then
            mod.enableDisableMutate(genome, false)
        end
        p = p - 1
    end
end

function mod.sameSpecies(genome1, genome2)
    local dd = DeltaDisjoint*disjoint(genome1.genes, genome2.genes)
    local dw = DeltaWeights*weights(genome1.genes, genome2.genes) 
    return dd + dw < DeltaThreshold
end

return mod
gneuron = require "neuron"
util = require "util"
local mod = {}

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
			neuron.value = util.sigmoid(sum)
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

return mod
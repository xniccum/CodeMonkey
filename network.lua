gneuron = require "neuron"
local mod = {}

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
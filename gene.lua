local gene = {}

function gene.newGene()
    local gene = {}
    gene.into = 0
    gene.out = 0
    gene.weight = 0.0
    gene.enabled = true
    gene.innovation = 0
    
    return gene
end

function gene.copyGene(gene)
    local gene2 = newGene()
    gene2.into = gene.into
    gene2.out = gene.out
    gene2.weight = gene.weight
    gene2.enabled = gene.enabled
    gene2.innovation = gene.innovation
    
    return gene2
end

function gene.containsLink(genes, link)
    for i=1,#genes do
        local gene = genes[i]
        if gene.into == link.into and gene.out == link.out then
            return true
        end
    end
end

function gene.disjoint(genes1, genes2)
    local i1 = {}
    for i = 1,#genes1 do
        local gene = genes1[i]
        i1[gene.innovation] = true
    end

    local i2 = {}
    for i = 1,#genes2 do
        local gene = genes2[i]
        i2[gene.innovation] = true
    end
    
    local disjointGenes = 0
    for i = 1,#genes1 do
        local gene = genes1[i]
        if not i2[gene.innovation] then
            disjointGenes = disjointGenes+1
        end
    end
    
    for i = 1,#genes2 do
        local gene = genes2[i]
        if not i1[gene.innovation] then
            disjointGenes = disjointGenes+1
        end
    end
    
    local n = math.max(#genes1, #genes2)
    
    return disjointGenes / n
end

function gene.weights(genes1, genes2)
    local i2 = {}
    for i = 1,#genes2 do
        local gene = genes2[i]
        i2[gene.innovation] = gene
    end

    local sum = 0
    local coincident = 0
    for i = 1,#genes1 do
        local gene = genes1[i]
        if i2[gene.innovation] ~= nil then
            local gene2 = i2[gene.innovation]
            sum = sum + math.abs(gene.weight - gene2.weight)
            coincident = coincident + 1
        end
    end
    
    return sum / coincident
end

return gene
function newPool()
    local pool = {}
    pool.species = {}
    pool.generation = 0
    pool.innovation = Outputs
    pool.currentSpecies = 1
    pool.currentGenome = 1
    pool.currentFrame = 0
    pool.maxFitness = 0
    return pool
end


local Meta = {}

local DEFINITIONS = {}
local LAYOUT = {}

local function addNode(args)
    local index = #DEFINITIONS + 1
    DEFINITIONS[index] = {
        key = args.key,
        name = args.name,
        desc = args.desc,
        category = args.category,
        icon = args.icon,
        deps = args.deps or {},
        maxLevel = args.maxLevel,
        baseCost = args.baseCost,
        scale = args.scale,
        bonusKey = args.bonusKey,
        bonusPerLevel = args.bonusPerLevel,
    }
    LAYOUT[index] = { x = args.x, y = args.y }
    return index
end

local refs = {}

refs.origin = addNode {
    key = "origin_heart",
    name = "Origin Heart",
    desc = "Unlocks the primal dragon lattice",
    category = "core",
    icon = "ORG",
    deps = {},
    maxLevel = 1,
    baseCost = 3,
    scale = 1.0,
    x = 0.0,
    y = 0.0,
}

local function addMainBranch(prefix, category, nodes)
    local out = {}
    for i, node in ipairs(nodes) do
        local deps = {}
        for _, depRef in ipairs(node.deps) do
            if depRef == "origin" then
                deps[#deps + 1] = refs.origin
            else
                deps[#deps + 1] = out[depRef]
            end
        end
        out[i] = addNode {
            key = prefix .. "_" .. node.key,
            name = node.name,
            desc = node.desc,
            category = category,
            icon = node.icon,
            deps = deps,
            maxLevel = node.maxLevel,
            baseCost = node.baseCost,
            scale = node.scale,
            bonusKey = node.bonusKey,
            bonusPerLevel = node.bonusPerLevel,
            x = node.x,
            y = node.y,
        }
    end
    return out
end

refs.up = addMainBranch("up", "mobility", {
    { key = "swift", name = "Swift Claw", desc = "Move speed +8 per level", icon = "SPD", deps = { "origin" }, maxLevel = 8, baseCost = 5, scale = 1.24, bonusKey = "speed", bonusPerLevel = 8, x = 0.0, y = -0.18 },
    { key = "maw", name = "Long Maw", desc = "Feeding reach +1.2 per level", icon = "MAW", deps = { 1 }, maxLevel = 8, baseCost = 7, scale = 1.25, bonusKey = "reach", bonusPerLevel = 1.2, x = 0.0, y = -0.36 },
    { key = "bite", name = "Snap Bite", desc = "Contact bite +4 per level", icon = "BTE", deps = { 2 }, maxLevel = 8, baseCost = 9, scale = 1.26, bonusKey = "contactBite", bonusPerLevel = 4, x = 0.0, y = -0.54 },
    { key = "rush", name = "Rush Spine", desc = "Move speed +12 per level", icon = "RSH", deps = { 3 }, maxLevel = 7, baseCost = 12, scale = 1.27, bonusKey = "speed", bonusPerLevel = 12, x = 0.0, y = -0.72 },
    { key = "crown", name = "Sky Crown", desc = "Contact bite +7 per level", icon = "CRN", deps = { 4 }, maxLevel = 6, baseCost = 17, scale = 1.28, bonusKey = "contactBite", bonusPerLevel = 7, x = 0.0, y = -0.9 },
    { key = "drift", name = "Drift Wing", desc = "Move speed +6 per level", icon = "DWF", deps = { 1 }, maxLevel = 7, baseCost = 7, scale = 1.25, bonusKey = "speed", bonusPerLevel = 6, x = -0.18, y = -0.18 },
    { key = "jaws", name = "Wide Jaws", desc = "Feeding reach +1.0 per level", icon = "JAW", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "reach", bonusPerLevel = 1.0, x = 0.18, y = -0.36 },
    { key = "ram", name = "Ram Crest", desc = "Contact bite +5 per level", icon = "RAM", deps = { 3 }, maxLevel = 6, baseCost = 11, scale = 1.27, bonusKey = "contactBite", bonusPerLevel = 5, x = -0.18, y = -0.54 },
    { key = "feather", name = "Wing Lash", desc = "Move speed +15 per level", icon = "LSH", deps = { 4 }, maxLevel = 6, baseCost = 15, scale = 1.28, bonusKey = "speed", bonusPerLevel = 15, x = 0.18, y = -0.72 },
    { key = "majesty", name = "Predator Crest", desc = "Feeding reach +2.1 per level", icon = "PRD", deps = { 5, 9 }, maxLevel = 5, baseCost = 22, scale = 1.3, bonusKey = "reach", bonusPerLevel = 2.1, x = 0.18, y = -0.9 },
})

refs.right = addMainBranch("right", "economy", {
    { key = "greed", name = "Greed Gland", desc = "Essence gain +6% per level", icon = "ECO", deps = { "origin" }, maxLevel = 8, baseCost = 5, scale = 1.24, bonusKey = "essenceMult", bonusPerLevel = 0.06, x = 0.18, y = 0.0 },
    { key = "lure", name = "Rare Lure", desc = "Rare spawn chance +0.8% per level", icon = "RAR", deps = { 1 }, maxLevel = 8, baseCost = 7, scale = 1.25, bonusKey = "rareBonus", bonusPerLevel = 0.008, x = 0.36, y = 0.0 },
    { key = "feast", name = "Elite Lure", desc = "Elite spawn chance +0.45% per level", icon = "ELT", deps = { 2 }, maxLevel = 8, baseCost = 10, scale = 1.26, bonusKey = "eliteBonus", bonusPerLevel = 0.0045, x = 0.54, y = 0.0 },
    { key = "hoard", name = "Hoard Belly", desc = "Essence gain +8% per level", icon = "GLD", deps = { 3 }, maxLevel = 7, baseCost = 13, scale = 1.27, bonusKey = "essenceMult", bonusPerLevel = 0.08, x = 0.72, y = 0.0 },
    { key = "royal", name = "Royal Stomach", desc = "Elite value +18% per level", icon = "ROY", deps = { 4 }, maxLevel = 6, baseCost = 18, scale = 1.29, bonusKey = "eliteValue", bonusPerLevel = 0.18, x = 0.9, y = 0.0 },
    { key = "gold", name = "Gold Scent", desc = "Rare value +10% per level", icon = "GLD", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "rareValue", bonusPerLevel = 0.10, x = 0.36, y = -0.18 },
    { key = "brood", name = "Brood Pull", desc = "Magnet radius +9 per level", icon = "MAG", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "magnet", bonusPerLevel = 9, x = 0.36, y = 0.18 },
    { key = "nest", name = "Dense Nest", desc = "Max field monsters +5 per level", icon = "POP", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "spawnCap", bonusPerLevel = 5, x = 0.54, y = -0.18 },
    { key = "bloom", name = "Feeding Bloom", desc = "Spawn speed +7% per level", icon = "SPN", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "spawnRate", bonusPerLevel = 0.07, x = 0.54, y = 0.18 },
    { key = "vault", name = "Vault Heart", desc = "Essence gain +12% per level", icon = "VLT", deps = { 5, 8 }, maxLevel = 5, baseCost = 24, scale = 1.3, bonusKey = "essenceMult", bonusPerLevel = 0.12, x = 0.9, y = -0.18 },
})

refs.down = addMainBranch("down", "combat", {
    { key = "fang", name = "Hunter Fang", desc = "Contact bite +5 per level", icon = "DMG", deps = { "origin" }, maxLevel = 8, baseCost = 5, scale = 1.24, bonusKey = "contactBite", bonusPerLevel = 5, x = 0.0, y = 0.18 },
    { key = "stride", name = "Chase Stride", desc = "Move speed +7 per level", icon = "SPD", deps = { 1 }, maxLevel = 8, baseCost = 7, scale = 1.25, bonusKey = "speed", bonusPerLevel = 7, x = 0.0, y = 0.36 },
    { key = "arc", name = "Arc Spine", desc = "Lightning chain count +1 per level", icon = "LNK", deps = { 2 }, maxLevel = 5, baseCost = 10, scale = 1.27, bonusKey = "lightningChain", bonusPerLevel = 1, x = 0.0, y = 0.54 },
    { key = "burst", name = "Burst Core", desc = "Fireball split shots +1 per level", icon = "FIR", deps = { 3 }, maxLevel = 4, baseCost = 14, scale = 1.28, bonusKey = "fireballSplit", bonusPerLevel = 1, x = 0.0, y = 0.72 },
    { key = "blizzard", name = "Blizzard Vein", desc = "Frost duration +0.25 sec per level", icon = "ICE", deps = { 4 }, maxLevel = 5, baseCost = 18, scale = 1.29, bonusKey = "frostDuration", bonusPerLevel = 0.25, x = 0.0, y = 0.9 },
    { key = "ram", name = "Crash Jaw", desc = "Contact bite +6 per level", icon = "JAW", deps = { 1 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "contactBite", bonusPerLevel = 6, x = -0.18, y = 0.18 },
    { key = "field", name = "Field Pull", desc = "Magnet radius +10 per level", icon = "PUL", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "magnet", bonusPerLevel = 10, x = 0.18, y = 0.36 },
    { key = "fork", name = "Fork Storm", desc = "Lightning damage +6 per level", icon = "THN", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "lightningDamage", bonusPerLevel = 6, x = -0.18, y = 0.54 },
    { key = "ember", name = "Ember Mouth", desc = "Fireball damage +5 per level", icon = "EMB", deps = { 4 }, maxLevel = 6, baseCost = 13, scale = 1.28, bonusKey = "fireballDamage", bonusPerLevel = 5, x = 0.18, y = 0.72 },
    { key = "cold", name = "Cold Maw", desc = "Frost damage +4 per level", icon = "CLD", deps = { 5, 9 }, maxLevel = 5, baseCost = 22, scale = 1.31, bonusKey = "frostDamage", bonusPerLevel = 4, x = 0.18, y = 0.9 },
})

refs.left = addMainBranch("left", "utility", {
    { key = "drag", name = "Drag Sense", desc = "Magnet radius +8 per level", icon = "MAG", deps = { "origin" }, maxLevel = 8, baseCost = 5, scale = 1.24, bonusKey = "magnet", bonusPerLevel = 8, x = -0.18, y = 0.0 },
    { key = "trail", name = "Trail Sniff", desc = "Spawn speed +6% per level", icon = "SNF", deps = { 1 }, maxLevel = 8, baseCost = 7, scale = 1.25, bonusKey = "spawnRate", bonusPerLevel = 0.06, x = -0.36, y = 0.0 },
    { key = "brood", name = "Brood Call", desc = "Max field monsters +6 per level", icon = "CAL", deps = { 2 }, maxLevel = 8, baseCost = 10, scale = 1.26, bonusKey = "spawnCap", bonusPerLevel = 6, x = -0.54, y = 0.0 },
    { key = "sweep", name = "Sweep Step", desc = "Move speed +10 per level", icon = "SWP", deps = { 3 }, maxLevel = 7, baseCost = 13, scale = 1.27, bonusKey = "speed", bonusPerLevel = 10, x = -0.72, y = 0.0 },
    { key = "vacuum", name = "Vacuum Maw", desc = "Magnet radius +16 per level", icon = "VAC", deps = { 4 }, maxLevel = 6, baseCost = 18, scale = 1.29, bonusKey = "magnet", bonusPerLevel = 16, x = -0.9, y = 0.0 },
    { key = "wide", name = "Wide Sweep", desc = "Feeding reach +1.1 per level", icon = "RNG", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "reach", bonusPerLevel = 1.1, x = -0.36, y = -0.18 },
    { key = "dash", name = "Dash Coil", desc = "Move speed +8 per level", icon = "DSH", deps = { 2 }, maxLevel = 7, baseCost = 8, scale = 1.25, bonusKey = "speed", bonusPerLevel = 8, x = -0.36, y = 0.18 },
    { key = "grid", name = "Field Grid", desc = "Essence gain +5% per level", icon = "GRD", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "essenceMult", bonusPerLevel = 0.05, x = -0.54, y = -0.18 },
    { key = "pack", name = "Pack Pull", desc = "Spawn speed +8% per level", icon = "PAC", deps = { 3 }, maxLevel = 6, baseCost = 12, scale = 1.27, bonusKey = "spawnRate", bonusPerLevel = 0.08, x = -0.54, y = 0.18 },
    { key = "storm", name = "Search Storm", desc = "Max field monsters +10 per level", icon = "SRH", deps = { 5, 8 }, maxLevel = 5, baseCost = 24, scale = 1.3, bonusKey = "spawnCap", bonusPerLevel = 10, x = -0.9, y = -0.18 },
})

local function addPassiveCluster(prefix, category, icon, rootDeps, points, defs)
    local indices = {}
    for i, def in ipairs(defs) do
        local deps = {}
        if i == 1 then
            for _, depIndex in ipairs(rootDeps) do
                deps[#deps + 1] = depIndex
            end
        else
            for _, depRef in ipairs(def.deps) do
                deps[#deps + 1] = indices[depRef]
            end
        end
        indices[i] = addNode {
            key = prefix .. "_" .. def.key,
            name = def.name,
            desc = def.desc,
            category = category,
            icon = def.icon or icon,
            deps = deps,
            maxLevel = def.maxLevel,
            baseCost = def.baseCost,
            scale = def.scale,
            bonusKey = def.bonusKey,
            bonusPerLevel = def.bonusPerLevel,
            x = points[i].x,
            y = points[i].y,
        }
    end
    return indices
end

local lightningPoints = {
    { x = 0.54, y = 0.54 }, { x = 0.72, y = 0.54 }, { x = 0.9, y = 0.54 }, { x = 1.08, y = 0.54 },
    { x = 0.72, y = 0.72 }, { x = 0.9, y = 0.72 }, { x = 0.9, y = 0.36 }, { x = 1.08, y = 0.36 },
    { x = 0.54, y = 0.72 }, { x = 0.54, y = 0.9 }, { x = 0.72, y = 0.9 }, { x = 0.9, y = 0.9 },
    { x = 1.08, y = 0.72 }, { x = 1.26, y = 0.72 }, { x = 1.26, y = 0.54 }, { x = 1.26, y = 0.36 },
}

local firePoints = {
    { x = -0.36, y = 0.72 }, { x = -0.54, y = 0.72 }, { x = -0.72, y = 0.72 }, { x = -0.9, y = 0.72 },
    { x = -0.54, y = 0.9 }, { x = -0.72, y = 0.9 }, { x = -0.72, y = 0.54 }, { x = -0.9, y = 0.54 },
    { x = -0.36, y = 0.9 }, { x = -0.36, y = 1.08 }, { x = -0.54, y = 1.08 }, { x = -0.72, y = 1.08 },
    { x = -0.9, y = 0.9 }, { x = -1.08, y = 0.9 }, { x = -1.08, y = 0.72 }, { x = -1.08, y = 0.54 },
}

local frostPoints = {
    { x = -0.54, y = -0.36 }, { x = -0.72, y = -0.36 }, { x = -0.9, y = -0.36 }, { x = -1.08, y = -0.36 },
    { x = -0.72, y = -0.54 }, { x = -0.9, y = -0.54 }, { x = -0.9, y = -0.18 }, { x = -1.08, y = -0.18 },
    { x = -0.54, y = -0.54 }, { x = -0.54, y = -0.72 }, { x = -0.72, y = -0.72 }, { x = -0.9, y = -0.72 },
    { x = -1.08, y = -0.54 }, { x = -1.26, y = -0.54 }, { x = -1.26, y = -0.36 }, { x = -1.26, y = -0.18 },
}

refs.lightning = addPassiveCluster("lightning", "lightning", "LIT", { refs.down[3], refs.right[3] }, lightningPoints, {
    { key = "root", name = "Storm Sigil", desc = "Unlock periodic lightning strikes", maxLevel = 1, baseCost = 18, scale = 1.0, bonusKey = "lightningEnabled", bonusPerLevel = 1 },
    { key = "dmg1", name = "Charged Fang", desc = "Lightning damage +8 per level", deps = { 1 }, maxLevel = 6, baseCost = 10, scale = 1.27, bonusKey = "lightningDamage", bonusPerLevel = 8 },
    { key = "rate1", name = "Storm Clock", desc = "Lightning cooldown -0.08 sec per level", deps = { 2 }, maxLevel = 6, baseCost = 12, scale = 1.28, bonusKey = "lightningIntervalCut", bonusPerLevel = 0.08 },
    { key = "dmg2", name = "Bright Wrath", desc = "Lightning damage +12 per level", deps = { 3 }, maxLevel = 5, baseCost = 16, scale = 1.29, bonusKey = "lightningDamage", bonusPerLevel = 12 },
    { key = "chain1", name = "Fork I", desc = "Lightning chain count +1 per level", deps = { 2 }, maxLevel = 3, baseCost = 13, scale = 1.28, bonusKey = "lightningChain", bonusPerLevel = 1 },
    { key = "chain2", name = "Fork II", desc = "Lightning chain count +1 per level", deps = { 5 }, maxLevel = 3, baseCost = 18, scale = 1.29, bonusKey = "lightningChain", bonusPerLevel = 1 },
    { key = "rate2", name = "Pulse Grid", desc = "Lightning cooldown -0.1 sec per level", deps = { 3 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "lightningIntervalCut", bonusPerLevel = 0.1 },
    { key = "dmg3", name = "Sky Split", desc = "Lightning damage +16 per level", deps = { 4 }, maxLevel = 4, baseCost = 20, scale = 1.3, bonusKey = "lightningDamage", bonusPerLevel = 16 },
    { key = "arc1", name = "Near Storm", desc = "Lightning damage +6 per level", deps = { 1 }, maxLevel = 5, baseCost = 11, scale = 1.27, bonusKey = "lightningDamage", bonusPerLevel = 6 },
    { key = "arc2", name = "Arc Well", desc = "Lightning cooldown -0.06 sec per level", deps = { 9 }, maxLevel = 5, baseCost = 13, scale = 1.28, bonusKey = "lightningIntervalCut", bonusPerLevel = 0.06 },
    { key = "arc3", name = "Thunder Mouth", desc = "Lightning damage +9 per level", deps = { 10 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "lightningDamage", bonusPerLevel = 9 },
    { key = "arc4", name = "Storm Halo", desc = "Lightning chain count +1 per level", deps = { 11 }, maxLevel = 2, baseCost = 22, scale = 1.3, bonusKey = "lightningChain", bonusPerLevel = 1 },
    { key = "surge1", name = "Overcharge", desc = "Lightning damage +18 per level", deps = { 4 }, maxLevel = 4, baseCost = 22, scale = 1.3, bonusKey = "lightningDamage", bonusPerLevel = 18 },
    { key = "surge2", name = "Static Sea", desc = "Lightning cooldown -0.12 sec per level", deps = { 13 }, maxLevel = 4, baseCost = 24, scale = 1.31, bonusKey = "lightningIntervalCut", bonusPerLevel = 0.12 },
    { key = "surge3", name = "Storm Spine", desc = "Lightning damage +24 per level", deps = { 14 }, maxLevel = 3, baseCost = 28, scale = 1.32, bonusKey = "lightningDamage", bonusPerLevel = 24 },
    { key = "apex", name = "World Flash", desc = "Lightning chain count +2 per level", deps = { 15, 8 }, maxLevel = 2, baseCost = 34, scale = 1.34, bonusKey = "lightningChain", bonusPerLevel = 2 },
})

refs.fireball = addPassiveCluster("fireball", "fireball", "FIR", { refs.down[4], refs.up[3] }, firePoints, {
    { key = "root", name = "Flame Sigil", desc = "Unlock periodic fireballs", maxLevel = 1, baseCost = 18, scale = 1.0, bonusKey = "fireballEnabled", bonusPerLevel = 1 },
    { key = "dmg1", name = "Hot Throat", desc = "Fireball damage +7 per level", deps = { 1 }, maxLevel = 6, baseCost = 10, scale = 1.27, bonusKey = "fireballDamage", bonusPerLevel = 7 },
    { key = "rate1", name = "Cinder Clock", desc = "Fireball cooldown -0.08 sec per level", deps = { 2 }, maxLevel = 6, baseCost = 12, scale = 1.28, bonusKey = "fireballIntervalCut", bonusPerLevel = 0.08 },
    { key = "dmg2", name = "Molten Gullet", desc = "Fireball damage +10 per level", deps = { 3 }, maxLevel = 5, baseCost = 16, scale = 1.29, bonusKey = "fireballDamage", bonusPerLevel = 10 },
    { key = "count1", name = "Twin Ember", desc = "Projectile count +1 per level", deps = { 2 }, maxLevel = 2, baseCost = 14, scale = 1.28, bonusKey = "fireballCount", bonusPerLevel = 1 },
    { key = "count2", name = "Tri Ember", desc = "Projectile count +1 per level", deps = { 5 }, maxLevel = 2, baseCost = 20, scale = 1.29, bonusKey = "fireballCount", bonusPerLevel = 1 },
    { key = "rate2", name = "Ash Valve", desc = "Fireball cooldown -0.1 sec per level", deps = { 3 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "fireballIntervalCut", bonusPerLevel = 0.1 },
    { key = "dmg3", name = "Salamander Core", desc = "Fireball damage +14 per level", deps = { 4 }, maxLevel = 4, baseCost = 20, scale = 1.3, bonusKey = "fireballDamage", bonusPerLevel = 14 },
    { key = "rad1", name = "Burst Ring", desc = "Explosion radius +10 per level", deps = { 1 }, maxLevel = 5, baseCost = 11, scale = 1.27, bonusKey = "fireballRadius", bonusPerLevel = 10 },
    { key = "rad2", name = "Lava Bloom", desc = "Explosion radius +12 per level", deps = { 9 }, maxLevel = 5, baseCost = 13, scale = 1.28, bonusKey = "fireballRadius", bonusPerLevel = 12 },
    { key = "rad3", name = "Sear Wave", desc = "Fireball damage +8 per level", deps = { 10 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "fireballDamage", bonusPerLevel = 8 },
    { key = "rad4", name = "Scorch Tail", desc = "Projectile count +1 per level", deps = { 11 }, maxLevel = 2, baseCost = 22, scale = 1.3, bonusKey = "fireballCount", bonusPerLevel = 1 },
    { key = "split1", name = "Split Spark", desc = "Split shots +1 per level", deps = { 4 }, maxLevel = 3, baseCost = 22, scale = 1.3, bonusKey = "fireballSplit", bonusPerLevel = 1 },
    { key = "split2", name = "Red Swarm", desc = "Fireball cooldown -0.12 sec per level", deps = { 13 }, maxLevel = 4, baseCost = 24, scale = 1.31, bonusKey = "fireballIntervalCut", bonusPerLevel = 0.12 },
    { key = "split3", name = "Inferno Jaw", desc = "Fireball damage +18 per level", deps = { 14 }, maxLevel = 3, baseCost = 28, scale = 1.32, bonusKey = "fireballDamage", bonusPerLevel = 18 },
    { key = "apex", name = "Sun Burst", desc = "Explosion radius +18 per level", deps = { 15, 8 }, maxLevel = 3, baseCost = 34, scale = 1.34, bonusKey = "fireballRadius", bonusPerLevel = 18 },
})

refs.frost = addPassiveCluster("frost", "frost", "ICE", { refs.left[3], refs.up[2] }, frostPoints, {
    { key = "root", name = "Frost Sigil", desc = "Unlock periodic frost pulses", maxLevel = 1, baseCost = 18, scale = 1.0, bonusKey = "frostEnabled", bonusPerLevel = 1 },
    { key = "dmg1", name = "Cold Breath", desc = "Frost damage +5 per level", deps = { 1 }, maxLevel = 6, baseCost = 10, scale = 1.27, bonusKey = "frostDamage", bonusPerLevel = 5 },
    { key = "rate1", name = "Cold Clock", desc = "Frost cooldown -0.08 sec per level", deps = { 2 }, maxLevel = 6, baseCost = 12, scale = 1.28, bonusKey = "frostIntervalCut", bonusPerLevel = 0.08 },
    { key = "dmg2", name = "Ice Lung", desc = "Frost damage +7 per level", deps = { 3 }, maxLevel = 5, baseCost = 16, scale = 1.29, bonusKey = "frostDamage", bonusPerLevel = 7 },
    { key = "slow1", name = "Slow Mist", desc = "Slow power +5% per level", deps = { 2 }, maxLevel = 4, baseCost = 13, scale = 1.28, bonusKey = "frostSlow", bonusPerLevel = 0.05 },
    { key = "slow2", name = "Deep Freeze", desc = "Slow power +6% per level", deps = { 5 }, maxLevel = 4, baseCost = 18, scale = 1.29, bonusKey = "frostSlow", bonusPerLevel = 0.06 },
    { key = "rate2", name = "Cold Spiral", desc = "Frost cooldown -0.1 sec per level", deps = { 3 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "frostIntervalCut", bonusPerLevel = 0.1 },
    { key = "dmg3", name = "Ice Bloom", desc = "Frost damage +10 per level", deps = { 4 }, maxLevel = 4, baseCost = 20, scale = 1.3, bonusKey = "frostDamage", bonusPerLevel = 10 },
    { key = "rad1", name = "Wide Chill", desc = "Frost radius +10 per level", deps = { 1 }, maxLevel = 5, baseCost = 11, scale = 1.27, bonusKey = "frostRadius", bonusPerLevel = 10 },
    { key = "rad2", name = "Cold Field", desc = "Frost radius +12 per level", deps = { 9 }, maxLevel = 5, baseCost = 13, scale = 1.28, bonusKey = "frostRadius", bonusPerLevel = 12 },
    { key = "rad3", name = "Biting Wind", desc = "Frost damage +6 per level", deps = { 10 }, maxLevel = 5, baseCost = 15, scale = 1.29, bonusKey = "frostDamage", bonusPerLevel = 6 },
    { key = "rad4", name = "Still Air", desc = "Frost duration +0.2 sec per level", deps = { 11 }, maxLevel = 4, baseCost = 22, scale = 1.3, bonusKey = "frostDuration", bonusPerLevel = 0.2 },
    { key = "veil1", name = "Frozen Veil", desc = "Frost radius +16 per level", deps = { 4 }, maxLevel = 4, baseCost = 22, scale = 1.3, bonusKey = "frostRadius", bonusPerLevel = 16 },
    { key = "veil2", name = "White Pulse", desc = "Frost cooldown -0.12 sec per level", deps = { 13 }, maxLevel = 4, baseCost = 24, scale = 1.31, bonusKey = "frostIntervalCut", bonusPerLevel = 0.12 },
    { key = "veil3", name = "Absolute Lung", desc = "Frost damage +14 per level", deps = { 14 }, maxLevel = 3, baseCost = 28, scale = 1.32, bonusKey = "frostDamage", bonusPerLevel = 14 },
    { key = "apex", name = "Winter Ring", desc = "Frost duration +0.35 sec per level", deps = { 15, 8 }, maxLevel = 3, baseCost = 34, scale = 1.34, bonusKey = "frostDuration", bonusPerLevel = 0.35 },
})

assert(#DEFINITIONS == 89, "meta tree must contain 89 nodes")

local function makeDefaultLevels()
    local levels = {}
    for _, def in ipairs(DEFINITIONS) do
        levels[def.key] = 0
    end
    return levels
end

local function getCost(def, level)
    return math.floor(def.baseCost * (def.scale ^ level))
end

local function depsSatisfied(meta, def)
    if not def.deps or #def.deps == 0 then
        return true
    end
    for _, depIndex in ipairs(def.deps) do
        local depDef = DEFINITIONS[depIndex]
        if not depDef or (meta.levels[depDef.key] or 0) <= 0 then
            return false
        end
    end
    return true
end

local function isVisible(meta, def)
    if not def.deps or #def.deps == 0 then
        return true
    end
    return depsSatisfied(meta, def)
end

function Meta.getDefinitions()
    return DEFINITIONS
end

function Meta.getTreeLayout()
    return LAYOUT
end

function Meta.new(saved)
    local levels = makeDefaultLevels()
    if saved and saved.levels then
        for key, value in pairs(saved.levels) do
            if levels[key] ~= nil then
                levels[key] = value
            end
        end
    end

    return {
        essence = saved and saved.essence or 0,
        totalRuns = saved and saved.totalRuns or 0,
        levels = levels,
    }
end

function Meta.export(meta)
    return {
        essence = meta.essence,
        totalRuns = meta.totalRuns,
        levels = meta.levels,
    }
end

function Meta.computeBonuses(meta)
    local bonuses = {
        speed = 0,
        reach = 0,
        magnet = 0,
        contactBite = 0,
        rareBonus = 0,
        eliteBonus = 0,
        spawnRate = 0,
        spawnCap = 0,
        essenceMult = 1,
        rareValue = 1,
        eliteValue = 1,
        lightningEnabled = 0,
        lightningDamage = 0,
        lightningChain = 0,
        lightningIntervalCut = 0,
        fireballEnabled = 0,
        fireballDamage = 0,
        fireballCount = 0,
        fireballRadius = 0,
        fireballIntervalCut = 0,
        fireballSplit = 0,
        frostEnabled = 0,
        frostDamage = 0,
        frostRadius = 0,
        frostSlow = 0,
        frostDuration = 0,
        frostIntervalCut = 0,
    }

    for _, def in ipairs(DEFINITIONS) do
        local level = meta.levels[def.key] or 0
        if level > 0 and def.bonusKey then
            bonuses[def.bonusKey] = bonuses[def.bonusKey] + def.bonusPerLevel * level
        end
    end

    return bonuses
end

function Meta.getUnlockedCount(meta)
    local count = 0
    for _, def in ipairs(DEFINITIONS) do
        if (meta.levels[def.key] or 0) > 0 then
            count = count + 1
        end
    end
    return count
end

function Meta.allUnlocked(meta)
    return Meta.getUnlockedCount(meta) >= #DEFINITIONS
end

function Meta.getUpgradeInfo(meta)
    local rows = {}
    for i, def in ipairs(DEFINITIONS) do
        local level = meta.levels[def.key] or 0
        local visible = isVisible(meta, def)
        local maxed = level >= def.maxLevel
        local cost = maxed and nil or getCost(def, level)
        local depsOk = depsSatisfied(meta, def)
        local canBuy = (not maxed) and depsOk and meta.essence >= cost
        local reason
        if maxed then
            reason = "MAX"
        elseif not depsOk then
            reason = "LOCKED"
        elseif meta.essence < cost then
            reason = "NEED ESSENCE"
        else
            reason = "BUY"
        end

        rows[#rows + 1] = {
            index = i,
            key = def.key,
            name = def.name,
            desc = def.desc,
            category = def.category,
            icon = def.icon,
            deps = def.deps,
            level = level,
            maxLevel = def.maxLevel,
            cost = cost,
            maxed = maxed,
            canBuy = canBuy,
            reason = reason,
            visible = visible,
            layout = LAYOUT[i],
        }
    end
    return rows
end

function Meta.tryBuy(meta, index)
    local def = DEFINITIONS[index]
    if not def then
        return false, "invalid index"
    end

    local level = meta.levels[def.key] or 0
    if level >= def.maxLevel then
        return false, "already max"
    end
    if not depsSatisfied(meta, def) then
        return false, "dependency missing"
    end

    local cost = getCost(def, level)
    if meta.essence < cost then
        return false, "not enough essence"
    end

    meta.essence = meta.essence - cost
    meta.levels[def.key] = level + 1
    return true, nil
end

return Meta

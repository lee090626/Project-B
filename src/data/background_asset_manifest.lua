local ProgressionBalance = require("src.data.progression_balance")

local ASSET_FIELDS = {
    backdropFar = "backdrop_far.png",
    backdropMid = "backdrop_mid.png",
    fieldBaseTile = "field_base_tile.png",
    fieldDecalSet = "field_decal_set.png",
    fieldFeature01 = "field_feature_01.png",
}

local function pathFor(slug, fileName)
    return "assets/backgrounds/" .. slug .. "/" .. fileName
end

local manifest = {}

for _, mapData in ipairs(ProgressionBalance.maps) do
    local slug = mapData.assetSlug
    if not slug or slug == "" then
        error(("missing assetSlug for map %s"):format(tostring(mapData.id)))
    end

    local entry = { version = mapData.assetVersion or 1 }
    for field, fileName in pairs(ASSET_FIELDS) do
        entry[field] = pathFor(slug, fileName)
    end
    manifest[mapData.id] = entry
end

return manifest

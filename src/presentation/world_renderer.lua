local C = require("src.constants")
local MapSystem = require("src.map_system")
local BackgroundRenderer = require("src.presentation.world_background_renderer")
local EntityRenderer = require("src.presentation.world_entity_renderer")
local FxRenderer = require("src.presentation.world_fx_renderer")
local Utils = require("src.presentation.world_render_utils")

local WorldRenderer = {}

function WorldRenderer.draw(state, assets)
    local mapData = MapSystem.getCurrentMap(state.maps)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local background = BackgroundRenderer.prepare(mapData, assets)

    BackgroundRenderer.drawScreenBackdrop(state, sw, sh, mapData, background)

    local left, top, right, bottom = Utils.getViewport(state, sw, sh)
    local view = {
        left = left,
        top = top,
        right = right,
        bottom = bottom,
        margin = C.WORLD_THEME.cullMargin,
    }

    love.graphics.push()
    love.graphics.scale(state.camera.zoom)
    love.graphics.translate(-state.camera.x, -state.camera.y)

    BackgroundRenderer.drawField(mapData.id, background)
    EntityRenderer.drawBossArena(state, view)
    EntityRenderer.drawFood(state, assets, view)
    EntityRenderer.drawBossWeakPoints(state, assets, view)
    EntityRenderer.drawBoss(state, assets, view)
    local playerVisible = EntityRenderer.drawPlayer(state, assets, view)
    FxRenderer.drawPassives(state, assets, view, playerVisible)

    love.graphics.pop()
end

return WorldRenderer

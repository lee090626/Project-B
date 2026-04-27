local WorldRenderer = require("src.presentation.world_renderer")
local OverlayRenderer = require("src.presentation.overlay_renderer")

local Renderer = {}

function Renderer.draw(state, fonts, ui, assets)
    if state.mode == "run_end_result" then
        WorldRenderer.draw(state, assets)
        OverlayRenderer.drawRunEndResultOverlay(state, fonts)
        OverlayRenderer.drawHelpPanel(state, fonts)
        return
    end

    if state.mode == "run_end_tree" then
        OverlayRenderer.drawRunEndTreeFullscreen(state, fonts)
        OverlayRenderer.drawHelpPanel(state, fonts)
        return
    end

    WorldRenderer.draw(state, assets)
    OverlayRenderer.drawGameTopBar(state, fonts, ui)
    OverlayRenderer.drawBossBar(state, fonts)
    OverlayRenderer.drawGameToasts(state, fonts)
    OverlayRenderer.drawHelpPanel(state, fonts)
end

return Renderer

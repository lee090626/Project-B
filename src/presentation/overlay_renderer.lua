local HudRenderer = require("src.presentation.hud_renderer")
local ModalRenderer = require("src.presentation.modal_renderer")
local RunEndRenderer = require("src.presentation.run_end_renderer")
local RunChoiceRenderer = require("src.presentation.run_choice_renderer")

local OverlayRenderer = {}

function OverlayRenderer.drawGameTopBar(state, fonts, ui, assets)
    return HudRenderer.drawGameTopBar(state, fonts, ui, assets)
end

function OverlayRenderer.drawBossBar(state, fonts)
    return HudRenderer.drawBossBar(state, fonts)
end

function OverlayRenderer.drawGameToasts(state, fonts)
    return HudRenderer.drawGameToasts(state, fonts)
end

function OverlayRenderer.drawGuidePanel(state, fonts, ui)
    return ModalRenderer.drawGuidePanel(state, fonts, ui)
end

function OverlayRenderer.drawHelpPanel(state, fonts)
    return ModalRenderer.drawHelpPanel(state, fonts)
end

function OverlayRenderer.drawRunEndTreeFullscreen(state, fonts, ui)
    return RunEndRenderer.drawRunEndTreeFullscreen(state, fonts, ui)
end

function OverlayRenderer.drawRunEndResultOverlay(state, fonts)
    return RunEndRenderer.drawRunEndResultOverlay(state, fonts)
end

function OverlayRenderer.drawRunChoiceOverlay(state, fonts, ui, assets)
    return RunChoiceRenderer.drawRunChoiceOverlay(state, fonts, ui, assets)
end

return OverlayRenderer

local C = require("src.constants")
local GameState = require("src.game_state")
local Locale = require("src.locale")

local Feedback = {}

function Feedback.nestedKey(key)
    return { key = key }
end

function Feedback.setMessage(state, key, params)
    GameState.setMessage(state, key, params)
    state.uiToastTimer = C.RUN_HUD_UI.toastDuration
end

function Feedback.refreshWindowTitle(state)
    love.window.setTitle(Locale.text(state.locale, "app.title"))
end

function Feedback.saveWithFeedback(state, reason)
    if state.mode == "run_choice" then
        GameState.setSaveStatus(state, "save_status.delayed_choice")
        return false
    end
    if state.mode == "boss_arena" then
        GameState.setSaveStatus(state, "save_status.delayed_boss")
        return false
    end
    local ok = GameState.saveNow(state, reason)
    if ok then
        state.uiAutosaveTimer = C.RUN_HUD_UI.autosaveDuration
    end
    return ok
end

function Feedback.localizedErrorRef(domain, code)
    if domain == "generic" then
        return Feedback.nestedKey("error.generic." .. code)
    end
    return Feedback.nestedKey("error." .. domain .. "." .. code)
end

return Feedback

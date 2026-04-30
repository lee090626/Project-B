local Locale = require("src.locale")

return {
    ref = Locale.ref,
    text = function(state, key, params)
        return Locale.text(state.locale, key, params)
    end,
    runReasonRef = function(reason)
        return Locale.ref("run_reason." .. tostring(reason or "unknown"))
    end,
}

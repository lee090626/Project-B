local Commands = require("src.application.game_command_service")
local LoopService = require("src.application.game_loop_service")
local MetaTreeController = require("src.application.meta_tree_controller")

local Service = {}

function Service.loadState()
    return Commands.loadState()
end

function Service.reloadState()
    return Commands.reloadState()
end

function Service.resetAllData()
    return Commands.resetAllData()
end

function Service.tick(state, dt)
    return LoopService.tick(state, dt)
end

function Service.save(state, reason)
    return Commands.save(state, reason)
end

function Service.toggleHelp(state)
    return Commands.toggleHelp(state)
end

function Service.cycleLocale(state)
    return Commands.cycleLocale(state)
end

function Service.trySwitchMap(state, mapId)
    return Commands.trySwitchMap(state, mapId)
end

function Service.tryEnterBoss(state)
    return Commands.tryEnterBoss(state)
end

function Service.tryBuyMetaUpgrade(state, index)
    return Commands.tryBuyMetaUpgrade(state, index)
end

function Service.tryBuyNestUpgrade(state, key)
    return Commands.tryBuyNestUpgrade(state, key)
end

function Service.restartRun(state)
    return Commands.restartRun(state)
end

function Service.openRunEndTree(state)
    return Commands.openRunEndTree(state)
end

function Service.openMetaTab(state)
    return Commands.openMetaTab(state)
end

function Service.openNestTab(state)
    return Commands.openNestTab(state)
end

function Service.chooseRunMutation(state, choiceIndex)
    return Commands.chooseRunMutation(state, choiceIndex)
end

function Service.dismissGuide(state)
    return Commands.dismissGuide(state)
end

function Service.metaUpgradeIndexAtScreen(state, sx, sy)
    return MetaTreeController.nodeAtScreen(state, sx, sy)
end

function Service.metaTreeScreenToWorld(state, sx, sy)
    return MetaTreeController.screenToWorld(state, sx, sy)
end

function Service.metaTreeNodeAtScreen(state, sx, sy)
    return MetaTreeController.nodeAtScreen(state, sx, sy)
end

function Service.panMetaTree(state, dx, dy)
    MetaTreeController.pan(state, dx, dy)
end

function Service.zoomMetaTree(state, wheelY)
    MetaTreeController.zoom(state, wheelY)
end

function Service.beginMetaTreePointer(state, x, y)
    MetaTreeController.beginPointer(state, x, y)
end

function Service.updateMetaTreePointer(state, _, _, dx, dy)
    MetaTreeController.updatePointer(state, nil, nil, dx, dy)
end

function Service.endMetaTreePointer(state, x, y)
    return MetaTreeController.endPointer(state, x, y)
end

return Service

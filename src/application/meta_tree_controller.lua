local C = require("src.constants")
local Utils = require("src.utils")
local Meta = require("src.meta_system")

local Controller = {}

function Controller.screenToWorld(state, sx, sy)
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local view = state.metaTreeView
    local scale = C.RUN_END_TREE_UI.worldScale
    local wx = (sx - sw * 0.5) / (view.zoom * scale) + view.cameraX
    local wy = (sy - sh * 0.5) / (view.zoom * scale) + view.cameraY
    return wx, wy
end

function Controller.nodeAtScreen(state, sx, sy)
    local wx, wy = Controller.screenToWorld(state, sx, sy)
    local rows = Meta.getUpgradeInfo(state.meta)
    local layout = Meta.getTreeLayout()
    local scale = C.RUN_END_TREE_UI.worldScale
    local view = state.metaTreeView
    local radius = C.RUN_END_TREE_UI.nodeRadius / (view.zoom * scale)
    local best
    local bestDistSq = radius * radius

    for _, row in ipairs(rows) do
        if row.visible then
            local point = layout[row.index]
            if point then
                local dx = wx - point.x
                local dy = wy - point.y
                local distSq = dx * dx + dy * dy
                if distSq < bestDistSq then
                    bestDistSq = distSq
                    best = row.index
                end
            end
        end
    end

    return best
end

function Controller.pan(state, dx, dy)
    local view = state.metaTreeView
    local scale = C.RUN_END_TREE_UI.worldScale
    view.cameraX = view.cameraX - dx / (view.zoom * scale)
    view.cameraY = view.cameraY - dy / (view.zoom * scale)
end

function Controller.zoom(state, wheelY)
    if wheelY == 0 then
        return
    end

    local view = state.metaTreeView
    local oldZoom = view.zoom
    local zoomStep = wheelY > 0 and C.RUN_END_TREE_UI.zoomStepUp or C.RUN_END_TREE_UI.zoomStepDown
    local newZoom = Utils.clamp(oldZoom * zoomStep, C.RUN_END_TREE_UI.minZoom, C.RUN_END_TREE_UI.maxZoom)
    if oldZoom == newZoom then
        return
    end

    local mx, my = love.mouse.getPosition()
    local wx, wy = Controller.screenToWorld(state, mx, my)
    view.zoom = newZoom

    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local scale = C.RUN_END_TREE_UI.worldScale
    view.cameraX = wx - (mx - sw * 0.5) / (newZoom * scale)
    view.cameraY = wy - (my - sh * 0.5) / (newZoom * scale)
end

function Controller.beginPointer(state, x, y)
    local view = state.metaTreeView
    view.pointerDown = true
    view.moved = false
    view.pressX = x
    view.pressY = y
end

function Controller.updatePointer(state, _, _, dx, dy)
    local view = state.metaTreeView
    if not view.pointerDown then
        return
    end

    local mx, my = love.mouse.getPosition()
    local movedDx = mx - view.pressX
    local movedDy = my - view.pressY
    local threshold = C.RUN_END_TREE_UI.clickThreshold

    if not view.moved and (movedDx * movedDx + movedDy * movedDy) >= (threshold * threshold) then
        view.moved = true
    end

    if view.moved then
        Controller.pan(state, dx, dy)
    end
end

function Controller.endPointer(state, x, y)
    local view = state.metaTreeView
    if not view.pointerDown then
        return nil
    end

    view.pointerDown = false
    if view.moved then
        return nil
    end

    return Controller.nodeAtScreen(state, x, y)
end

return Controller

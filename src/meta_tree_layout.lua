local C = require("src.constants")

local Layout = {}

local function bounds(points)
    local minX, maxX = 999, -999
    local minY, maxY = 999, -999
    for _, p in pairs(points) do
        minX = math.min(minX, p.x)
        maxX = math.max(maxX, p.x)
        minY = math.min(minY, p.y)
        maxY = math.max(maxY, p.y)
    end
    return minX, maxX, minY, maxY
end

function Layout.build(screenW, screenH, treeLayout, visibleIndices)
    local ui = C.RUN_END_TREE_UI
    local panel = {
        x = screenW * ui.panel.x,
        y = screenH * ui.panel.y,
        w = screenW * ui.panel.w,
        h = screenH * ui.panel.h,
    }

    local gap = ui.sectionGap
    local inset = ui.contentInset
    local innerX = panel.x + inset
    local innerY = panel.y + inset
    local innerW = panel.w - inset * 2
    local innerH = panel.h - inset * 2

    local headerH = innerH * ui.sections.header
    local treeH = innerH * ui.sections.tree
    local tooltipH = innerH * ui.sections.tooltip
    local footerH = math.max(0, innerH * ui.sections.footer)

    local headerRect = { x = innerX, y = innerY, w = innerW, h = headerH }
    local treeRect = { x = innerX, y = headerRect.y + headerRect.h + gap, w = innerW, h = treeH - gap }
    local tooltipRect = { x = innerX, y = treeRect.y + treeRect.h + gap, w = innerW, h = tooltipH - gap }
    local footerRect = { x = innerX, y = tooltipRect.y + tooltipRect.h + gap, w = innerW, h = footerH - gap }

    local activeLayout = {}
    local activeCount = 0
    if visibleIndices then
        for idx, enabled in pairs(visibleIndices) do
            if enabled and treeLayout[idx] then
                activeLayout[idx] = treeLayout[idx]
                activeCount = activeCount + 1
            end
        end
    else
        activeLayout = treeLayout
    end
    if activeCount <= 1 then
        activeLayout = treeLayout
    end

    local minX, maxX, minY, maxY = bounds(activeLayout)
    local spanX = math.max(0.001, maxX - minX)
    local spanY = math.max(0.001, maxY - minY)
    local safe = ui.safePadding
    local content = {
        x = treeRect.x + safe,
        y = treeRect.y + safe,
        w = math.max(1, treeRect.w - safe * 2),
        h = math.max(1, treeRect.h - safe * 2),
    }

    local function project(index)
        if visibleIndices and not visibleIndices[index] then
            return nil
        end
        local p = treeLayout[index]
        if not p then
            return nil
        end
        local nx = (p.x - minX) / spanX
        local ny = (p.y - minY) / spanY
        return {
            x = content.x + nx * content.w,
            y = content.y + ny * content.h,
        }
    end

    local function hitTest(sx, sy)
        for idx, _ in pairs(activeLayout) do
            local p = project(idx)
            if p and (math.abs(sx - p.x) + math.abs(sy - p.y) <= ui.hitRadius) then
                return idx
            end
        end
        return nil
    end

    return {
        panel = panel,
        headerRect = headerRect,
        treeRect = treeRect,
        tooltipRect = tooltipRect,
        footerRect = footerRect,
        project = project,
        hitTest = hitTest,
    }
end

return Layout

local WorldRenderUtils = {}

function WorldRenderUtils.angleFromVector(dx, dy)
    if dx == 0 then
        if dy > 0 then
            return math.pi * 0.5
        elseif dy < 0 then
            return -math.pi * 0.5
        end
        return 0
    end

    local angle = math.atan(dy / dx)
    if dx < 0 then
        angle = angle + math.pi
    end
    return angle
end

function WorldRenderUtils.setPaletteColor(color, alphaMul)
    local a = (color[4] or 1) * (alphaMul or 1)
    love.graphics.setColor(color[1], color[2], color[3], a)
end

function WorldRenderUtils.getViewport(state, sw, sh)
    local left = state.camera.x
    local top = state.camera.y
    local right = left + sw / state.camera.zoom
    local bottom = top + sh / state.camera.zoom
    return left, top, right, bottom
end

function WorldRenderUtils.isCircleVisible(x, y, radius, left, top, right, bottom, margin)
    local pad = radius + (margin or 0)
    return x + pad >= left and x - pad <= right and y + pad >= top and y - pad <= bottom
end

function WorldRenderUtils.isSegmentVisible(x1, y1, x2, y2, left, top, right, bottom, margin)
    local pad = margin or 0
    local minX = math.min(x1, x2) - pad
    local maxX = math.max(x1, x2) + pad
    local minY = math.min(y1, y2) - pad
    local maxY = math.max(y1, y2) + pad
    return maxX >= left and minX <= right and maxY >= top and minY <= bottom
end

function WorldRenderUtils.drawSpriteCentered(sprite, x, y, targetSize, rotation, tint)
    local iw = sprite:getWidth()
    local ih = sprite:getHeight()
    local scale = targetSize / math.max(iw, ih)
    local color = tint or { 1, 1, 1, 1 }
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.draw(sprite, x, y, rotation or 0, scale, scale, iw * 0.5, ih * 0.5)
end

return WorldRenderUtils

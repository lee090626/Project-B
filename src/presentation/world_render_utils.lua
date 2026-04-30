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

function WorldRenderUtils.isCircleInView(x, y, radius, view)
    local pad = radius + (view.margin or 0)
    return x + pad >= view.left and x - pad <= view.right and y + pad >= view.top and y - pad <= view.bottom
end

function WorldRenderUtils.isSegmentInView(x1, y1, x2, y2, view)
    local pad = view.margin or 0
    local minX = math.min(x1, x2) - pad
    local maxX = math.max(x1, x2) + pad
    local minY = math.min(y1, y2) - pad
    local maxY = math.max(y1, y2) + pad
    return maxX >= view.left and minX <= view.right and maxY >= view.top and minY <= view.bottom
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

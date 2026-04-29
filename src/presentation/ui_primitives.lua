local UiPrimitives = {}

function UiPrimitives.ellipsize(font, text, maxWidth)
    if font:getWidth(text) <= maxWidth then
        return text
    end
    local suffix = "..."
    local out = text
    while #out > 1 and font:getWidth(out .. suffix) > maxWidth do
        out = out:sub(1, #out - 1)
    end
    return out .. suffix
end

function UiPrimitives.setPaletteColor(color, alphaMul)
    local a = (color[4] or 1) * (alphaMul or 1)
    love.graphics.setColor(color[1], color[2], color[3], a)
end

local function drawDiamond(x, y, radius)
    love.graphics.polygon("line", x, y - radius, x + radius, y, x, y + radius, x - radius, y)
end

function UiPrimitives.drawIconAtSize(image, x, y, size)
    if not image or not size or size <= 0 then
        return false
    end

    local iw = image:getWidth()
    local ih = image:getHeight()
    if iw <= 0 or ih <= 0 then
        return false
    end

    local scale = size / math.max(iw, ih)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, x, y, 0, scale, scale, iw * 0.5, ih * 0.5)
    return true
end

local function buildStarPoints(x, y, outerRadius, innerRadius)
    local points = {}
    for i = 0, 9 do
        local angle = -math.pi * 0.5 + i * math.pi * 0.2
        local radius = (i % 2 == 0) and outerRadius or innerRadius
        points[#points + 1] = x + math.cos(angle) * radius
        points[#points + 1] = y + math.sin(angle) * radius
    end
    return points
end

function UiPrimitives.drawDecoratedPanel(x, y, w, h, theme, alphaMul, options)
    UiPrimitives.setPaletteColor(theme.panelFill, alphaMul)
    love.graphics.rectangle("fill", x, y, w, h, 14, 14)
    UiPrimitives.setPaletteColor(theme.panelInner or theme.panelFill, 0.72 * (alphaMul or 1))
    love.graphics.rectangle("fill", x + 8, y + 8, w - 16, h - 16, 10, 10)
    UiPrimitives.setPaletteColor(theme.panelGlow or theme.panelLine, alphaMul)
    love.graphics.rectangle("line", x + 3, y + 3, w - 6, h - 6, 12, 12)
    UiPrimitives.setPaletteColor(theme.panelLine, alphaMul)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 14, 14)

    if not (options and options.hideCorners) then
        local corner = 8
        UiPrimitives.setPaletteColor(theme.accent or theme.panelLine, 0.9 * (alphaMul or 1))
        love.graphics.polygon("fill", x + 14, y + 8, x + 14 + corner, y + 14, x + 14, y + 20, x + 14 - corner, y + 14)
        love.graphics.polygon("fill", x + w - 14, y + 8, x + w - 14 + corner, y + 14, x + w - 14, y + 20, x + w - 14 - corner, y + 14)
    end
end

function UiPrimitives.drawPanelRule(x, y, w, color, alphaMul)
    UiPrimitives.setPaletteColor(color, alphaMul)
    love.graphics.setLineWidth(2)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x + w * 0.32, y - 4, x + w * 0.5, y - 4)
    love.graphics.line(x + w * 0.5, y + 4, x + w * 0.68, y + 4)
end

function UiPrimitives.drawRuneBadge(kind, x, y, radius, fillColor, lineColor)
    love.graphics.setLineWidth(2)
    UiPrimitives.setPaletteColor(fillColor)
    love.graphics.circle("fill", x, y, radius)
    UiPrimitives.setPaletteColor(lineColor)
    love.graphics.circle("line", x, y, radius)

    if kind == "time" then
        love.graphics.line(x, y, x, y - radius * 0.45)
        love.graphics.line(x, y, x + radius * 0.32, y)
    elseif kind == "map" then
        drawDiamond(x, y, radius * 0.48)
        love.graphics.line(x, y - radius * 0.48, x, y + radius * 0.48)
    elseif kind == "star" then
        local fillPoints = buildStarPoints(x, y, radius * 0.42, radius * 0.2)
        local linePoints = buildStarPoints(x, y, radius * 0.56, radius * 0.26)
        UiPrimitives.setPaletteColor(fillColor)
        love.graphics.polygon("fill", fillPoints)
        UiPrimitives.setPaletteColor(lineColor)
        love.graphics.polygon("line", linePoints)
    elseif kind == "essence" then
        love.graphics.circle("fill", x, y, radius * 0.34)
        love.graphics.arc("line", "open", x, y, radius * 0.6, -math.pi * 0.15, math.pi * 1.15)
    elseif kind == "level" then
        love.graphics.line(x - radius * 0.4, y + radius * 0.35, x, y - radius * 0.45)
        love.graphics.line(x, y - radius * 0.45, x + radius * 0.4, y + radius * 0.35)
        love.graphics.line(x - radius * 0.26, y + radius * 0.06, x + radius * 0.26, y + radius * 0.06)
    elseif kind == "instinct" then
        love.graphics.arc("line", "open", x - radius * 0.16, y, radius * 0.44, -math.pi * 0.4, math.pi * 0.4)
        love.graphics.arc("line", "open", x + radius * 0.16, y, radius * 0.44, math.pi * 0.6, math.pi * 1.4)
        love.graphics.circle("fill", x, y, radius * 0.14)
    elseif kind == "save" then
        love.graphics.rectangle("line", x - radius * 0.34, y - radius * 0.34, radius * 0.68, radius * 0.68, 3, 3)
        love.graphics.line(x - radius * 0.18, y - radius * 0.08, x + radius * 0.18, y - radius * 0.08)
        love.graphics.line(x - radius * 0.14, y + radius * 0.2, x + radius * 0.14, y + radius * 0.2)
    elseif kind == "help" then
        love.graphics.arc("line", "open", x, y - radius * 0.08, radius * 0.34, math.pi, math.pi * 2)
        love.graphics.line(x + radius * 0.16, y + radius * 0.02, x, y + radius * 0.22)
        love.graphics.circle("fill", x, y + radius * 0.42, radius * 0.06)
    elseif kind == "boss" then
        love.graphics.line(x - radius * 0.36, y + radius * 0.3, x - radius * 0.12, y - radius * 0.26)
        love.graphics.line(x + radius * 0.36, y + radius * 0.3, x + radius * 0.12, y - radius * 0.26)
        love.graphics.line(x - radius * 0.12, y - radius * 0.26, x + radius * 0.12, y - radius * 0.26)
    elseif kind == "hunt" then
        love.graphics.line(x - radius * 0.3, y + radius * 0.24, x, y - radius * 0.32)
        love.graphics.line(x + radius * 0.18, y + radius * 0.26, x, y - radius * 0.32)
    elseif kind == "stomach" then
        love.graphics.circle("line", x, y, radius * 0.4)
        love.graphics.circle("fill", x, y, radius * 0.12)
    elseif kind == "sense" then
        love.graphics.arc("line", "open", x, y, radius * 0.56, math.pi * 0.15, math.pi * 0.85)
        love.graphics.arc("line", "open", x, y, radius * 0.56, math.pi * 1.15, math.pi * 1.85)
        love.graphics.circle("fill", x, y, radius * 0.12)
    elseif kind == "spawn" then
        for i = 0, 3 do
            local angle = i * math.pi * 0.5
            love.graphics.line(x, y, x + math.cos(angle) * radius * 0.42, y + math.sin(angle) * radius * 0.42)
        end
        love.graphics.circle("fill", x, y, radius * 0.1)
    end
end

function UiPrimitives.drawKeyChip(font, x, y, keyLabel, desc, theme)
    local padX = 10
    local keyW = font:getWidth(keyLabel) + padX * 2
    local descW = font:getWidth(desc)
    local totalW = keyW + 10 + descW

    UiPrimitives.setPaletteColor(theme.chipFill)
    love.graphics.rectangle("fill", x, y, keyW, 24, 8, 8)
    UiPrimitives.setPaletteColor(theme.chipLine)
    love.graphics.rectangle("line", x, y, keyW, 24, 8, 8)
    UiPrimitives.setPaletteColor(theme.text or theme.panelLine)
    love.graphics.print(keyLabel, x + padX, y + 4)
    UiPrimitives.setPaletteColor(theme.dim or theme.text)
    love.graphics.print(desc, x + keyW + 10, y + 4)
    return totalW
end

function UiPrimitives.drawProgressBar(x, y, w, h, pct, theme, complete)
    pct = math.max(0, math.min(1, pct or 0))
    UiPrimitives.setPaletteColor(theme.progressBg)
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)
    UiPrimitives.setPaletteColor(complete and theme.progressDone or theme.progressFill)
    love.graphics.rectangle("fill", x + 2, y + 2, math.max(0, (w - 4) * pct), h - 4, 4, 4)
    UiPrimitives.setPaletteColor(theme.panelLine)
    love.graphics.rectangle("line", x, y, w, h, 5, 5)
end

return UiPrimitives

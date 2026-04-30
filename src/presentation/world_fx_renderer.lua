local C = require("src.constants")
local Utils = require("src.presentation.world_render_utils")

local WorldFxRenderer = {}

function WorldFxRenderer.drawPassives(state, assets, view, playerVisible)
    if state.passives then
        if state.passives.eatFxTimer and state.passives.eatFxTimer > 0
            and playerVisible then
            local a = state.passives.eatFxTimer / 0.18
            local radius = (state.passives.eatFxRadius or C.WORLD_THEME.eatPulseMinRadius) * (1.18 - a * 0.2)
            love.graphics.setColor(1.0, 0.82, 0.34, 0.12 * a)
            love.graphics.circle("fill", state.player.x, state.player.y, radius)
            love.graphics.setColor(1.0, 0.95, 0.72, 0.72 * a)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", state.player.x, state.player.y, radius)
        end

        if state.passives.lightningFx then
            local fx = state.passives.lightningFx
            local a = math.max(0, fx.timer / 0.18)
            love.graphics.setColor(0.8, 0.95, 1.0, a)
            love.graphics.setLineWidth(4)
            for _, segment in ipairs(fx.segments or {}) do
                if Utils.isSegmentInView(segment.fromX, segment.fromY, segment.toX, segment.toY, view) then
                    love.graphics.line(segment.fromX, segment.fromY, segment.toX, segment.toY)
                    love.graphics.circle("fill", segment.toX, segment.toY, 4)
                end
            end
        end

        if state.passives.fireballProjectiles then
            for _, projectile in ipairs(state.passives.fireballProjectiles) do
                local projectileVisible = Utils.isCircleInView(
                    projectile.x,
                    projectile.y,
                    math.max(12, projectile.radius * 0.75),
                    view
                )
                local trailVisible = Utils.isSegmentInView(
                    projectile.prevX,
                    projectile.prevY,
                    projectile.x,
                    projectile.y,
                    view
                )

                if trailVisible then
                    love.graphics.setColor(1.0, 0.68, 0.24, 0.28)
                    love.graphics.setLineWidth(2)
                    love.graphics.line(projectile.prevX, projectile.prevY, projectile.x, projectile.y)
                end

                if projectileVisible then
                    if assets and assets.fireballSprite then
                        local sprite = assets.fireballSprite
                        local iw = sprite:getWidth()
                        local ih = sprite:getHeight()
                        local diameter = math.max(40, projectile.radius * 1.35)
                        local scale = diameter / math.max(iw, ih)
                        local angle = Utils.angleFromVector(projectile.vx, projectile.vy)
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.draw(sprite, projectile.x, projectile.y, angle, scale, scale, iw * 0.5, ih * 0.5)
                    else
                        love.graphics.setColor(1.0, 0.42, 0.16)
                        love.graphics.circle("fill", projectile.x, projectile.y, math.max(7, projectile.radius * 0.16))
                    end

                    love.graphics.setColor(1.0, 0.86, 0.5, 0.12)
                    love.graphics.circle("fill", projectile.x, projectile.y, math.max(6, projectile.radius * C.WORLD_THEME.fireballGlowScale))
                end
            end
        end

        if state.passives.fireballImpacts then
            for _, impact in ipairs(state.passives.fireballImpacts) do
                if Utils.isCircleInView(impact.x, impact.y, impact.radius, view) then
                    local a = math.max(0, impact.timer / C.PASSIVE_BASES.fireball.impactFxDuration)
                    love.graphics.setColor(1.0, 0.52, 0.18, 0.1 * a)
                    love.graphics.circle("fill", impact.x, impact.y, impact.radius * C.WORLD_THEME.fireballImpactFillScale)
                    love.graphics.setColor(1.0, 0.82, 0.36, 0.7 * a)
                    love.graphics.setLineWidth(2)
                    love.graphics.circle("line", impact.x, impact.y, impact.radius * (0.55 + (1 - a) * 0.45))
                end
            end
        end
    end
end

return WorldFxRenderer

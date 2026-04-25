local GameApp = require("src.application.game_app")

local app

function love.load()
    app = GameApp.new()
    app:load()
end

function love.update(dt)
    app:update(dt)
end

function love.draw()
    app:draw()
end

function love.keypressed(key)
    local ctrlOrCmd = love.keyboard.isDown("lctrl", "rctrl", "lgui", "rgui")
    if ctrlOrCmd and key == "r" then
        love.event.quit("restart")
        return
    end

    app:keypressed(key)
end

function love.mousepressed(x, y, button)
    app:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    app:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    app:mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    app:wheelmoved(x, y)
end

function love.quit()
    app:quit()
end

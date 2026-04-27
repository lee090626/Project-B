local Service = require("src.application.game_service")
local Renderer = require("src.presentation.game_renderer")

local App = {}
App.__index = App

function App.new()
    return setmetatable({
        state = nil,
        fonts = {},
        assets = {},
        ui = { saveBtn = { x = 0, y = 0, w = 120, h = 32 } },
    }, App)
end

function App:load()
    love.window.setTitle("Baby Dragon Incremental v1")
    love.window.setMode(1280, 720, { resizable = true, minwidth = 960, minheight = 540 })

    self.fonts.hud = love.graphics.newFont(15)
    self.fonts.big = love.graphics.newFont(30)

    local ok, playerImage = pcall(love.graphics.newImage, "BabyDragon.png")
    if ok and playerImage then
        self.assets.playerSprite = playerImage
    else
        self.assets.playerSprite = nil
    end

    self.state = Service.loadState()
end

function App:update(dt)
    Service.tick(self.state, dt)
end

function App:draw()
    Renderer.draw(self.state, self.fonts, self.ui, self.assets)
end

function App:keypressed(key)
    if key == "h" then
        Service.toggleHelp(self.state)
        return
    end

    if key == "f5" then
        Service.save(self.state, "manual")
        return
    end

    if key == "f9" then
        self.state = Service.reloadState()
        return
    end

    if key == "f10" then
        self.state = Service.resetAllData()
        return
    end

    if self.state.mode == "run_end_tree" then
        if key == "r" then
            Service.restartRun(self.state)
            return
        end
        return
    end

    if self.state.mode == "run_end_result" then
        return
    end

    if key == "b" then
        Service.tryEnterBoss(self.state)
        return
    end

    local mapId = tonumber(key)
    if mapId then
        Service.trySwitchMap(self.state, mapId)
    end
end

function App:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    if self.state.mode == "run_end_tree" then
        Service.beginMetaTreePointer(self.state, x, y)
        return
    end

    if self.state.mode == "run_end_result" then
        Service.openRunEndTree(self.state)
        return
    end

    local saveBtn = self.ui.saveBtn
    local inSaveButton = x >= saveBtn.x and x <= saveBtn.x + saveBtn.w and y >= saveBtn.y and y <= saveBtn.y + saveBtn.h
    if inSaveButton then
        Service.save(self.state, "manual-button")
    end
end

function App:mousereleased(x, y, button)
    if button ~= 1 then
        return
    end

    if self.state.mode == "run_end_tree" then
        local idx = Service.endMetaTreePointer(self.state, x, y)
        if idx then
            Service.tryBuyMetaUpgrade(self.state, idx)
        end
        return
    end

    if self.state.mode == "run_end_result" then
        return
    end
end

function App:mousemoved(x, y, dx, dy)
    if self.state.mode == "run_end_tree" then
        Service.updateMetaTreePointer(self.state, x, y, dx, dy)
        return
    end
end

function App:wheelmoved(_, y)
    if self.state.mode == "run_end_tree" then
        Service.zoomMetaTree(self.state, y)
    end
end

function App:quit()
    Service.save(self.state, "quit")
end

return App

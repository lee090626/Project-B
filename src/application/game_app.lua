local Service = require("src.application.game_service")
local Locale = require("src.locale")
local Renderer = require("src.presentation.game_renderer")

local App = {}
App.__index = App

local UI_FONT_PATH = "fonts/NanumGothic-Regular.ttf"

function App.new()
    return setmetatable({
        state = nil,
        fonts = {},
        assets = {},
        ui = {
            saveBtn = { x = 0, y = 0, w = 120, h = 32 },
            runEnd = { tabs = {}, nestButtons = {} },
            runChoice = { cards = {} },
        },
    }, App)
end

local function hitRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.w
        and y >= rect.y
        and y <= rect.y + rect.h
end

local function loadUiFont(size)
    local ok, font = pcall(love.graphics.newFont, UI_FONT_PATH, size)
    if ok and font then
        return font
    end
    return love.graphics.newFont(size)
end

function App:load()
    love.window.setTitle(Locale.text(Locale.DEFAULT, "app.title"))
    love.window.setMode(1280, 720, { resizable = true, minwidth = 960, minheight = 540 })

    self.fonts.hud = loadUiFont(15)
    self.fonts.big = loadUiFont(30)

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

    if key == "l" and self.state.showHelp then
        Service.cycleLocale(self.state)
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
        if key == "tab" then
            if self.state.runEndTab == "meta" then
                Service.openNestTab(self.state)
            else
                Service.openMetaTab(self.state)
            end
            return
        end
        if key == "r" then
            Service.restartRun(self.state)
            return
        end
        return
    end

    if self.state.mode == "run_choice" then
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

    if self.state.mode == "run_choice" then
        for index, rect in ipairs(self.ui.runChoice.cards) do
            if hitRect(x, y, rect) then
                Service.chooseRunMutation(self.state, index)
                return
            end
        end
        return
    end

    if self.state.mode == "run_end_tree" then
        for name, rect in pairs(self.ui.runEnd.tabs) do
            if hitRect(x, y, rect) then
                if name == "meta" then
                    Service.openMetaTab(self.state)
                else
                    Service.openNestTab(self.state)
                end
                return
            end
        end

        if self.state.runEndTab == "nest" then
            for _, row in ipairs(self.ui.runEnd.nestButtons) do
                if hitRect(x, y, row) then
                    Service.tryBuyNestUpgrade(self.state, row.key)
                    return
                end
            end
            return
        end

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
        if self.state.runEndTab ~= "meta" then
            return
        end
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
    if self.state.mode == "run_end_tree" and self.state.runEndTab == "meta" then
        Service.updateMetaTreePointer(self.state, x, y, dx, dy)
        return
    end
end

function App:wheelmoved(_, y)
    if self.state.mode == "run_end_tree" and self.state.runEndTab == "meta" then
        Service.zoomMetaTree(self.state, y)
    end
end

function App:quit()
    Service.save(self.state, "quit")
end

return App

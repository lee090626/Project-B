---@meta

---@class love_image
local love_image = {}
function love_image:getWidth() end
function love_image:getHeight() end

---@class love_font
local love_font = {}
---@return integer
function love_font:getWidth(text) end

---@class love_filesystem
local love_filesystem = {}
---@return table|nil
function love_filesystem.getInfo(path) end
---@return string|nil, string|nil
function love_filesystem.read(path) end
---@return boolean, string|nil
function love_filesystem.write(path, data) end
---@return boolean, string|nil
function love_filesystem.remove(path) end

---@class love_graphics
local love_graphics = {}
---@return integer
function love_graphics.getWidth() end
---@return integer
function love_graphics.getHeight() end
---@return love_font
function love_graphics.newFont(size) end
---@return love_image
function love_graphics.newImage(path) end
function love_graphics.setColor(...) end
function love_graphics.rectangle(mode, x, y, w, h, rx, ry) end
function love_graphics.circle(mode, x, y, radius) end
function love_graphics.line(...) end
function love_graphics.polygon(mode, ...) end
function love_graphics.draw(drawable, x, y, r, sx, sy, ox, oy) end
function love_graphics.push() end
function love_graphics.pop() end
function love_graphics.scale(sx, sy) end
function love_graphics.translate(dx, dy) end
function love_graphics.setFont(font) end
function love_graphics.setLineWidth(width) end
function love_graphics.print(text, x, y) end
function love_graphics.printf(text, x, y, limit, align) end

---@class love_keyboard
local love_keyboard = {}
---@return boolean
function love_keyboard.isDown(...) end

---@class love_math
local love_math = {}
---@return number
function love_math.random(m, n) end

---@class love_mouse
local love_mouse = {}
---@return number, number
function love_mouse.getPosition() end

---@class love_window
local love_window = {}
function love_window.setTitle(title) end
function love_window.setMode(width, height, flags) end

---@class love_event
local love_event = {}
function love_event.quit(code) end

---@class love
love = {
  graphics = love_graphics,
  keyboard = love_keyboard,
  filesystem = love_filesystem,
  math = love_math,
  mouse = love_mouse,
  window = love_window,
  event = love_event
}

function love.load() end
function love.update(dt) end
function love.draw() end
function love.keypressed(key) end
function love.mousepressed(x, y, button) end
function love.mousereleased(x, y, button) end
function love.mousemoved(x, y, dx, dy) end
function love.wheelmoved(x, y) end
function love.quit() end

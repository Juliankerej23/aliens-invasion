local Game=require("src.game")
local Net=require("src.net")

function love.load()
  love.window.setTitle("Aliens Invasion LAN v39")
  love.graphics.setDefaultFilter("nearest","nearest")
  love.keyboard.setKeyRepeat(false)
  love.graphics.setLineStyle("rough")
  Game.load()
  Net.init(22122)
end

function love.update(dt)
  Game.update(dt,Net)
  Net.update(dt,Game)
end

function love.draw()
  Game.draw(Net)
end

function love.keypressed(k)
  Game.keypressed(k,Net)
end

function love.touchpressed(id,x,y,dx,dy,p)
  Game.touchpressed(id,x,y,dx,dy,p,Net)
end

function love.touchreleased(id,x,y,dx,dy,p)
  Game.touchreleased(id,x,y,dx,dy,p)
end

function love.textinput(t)
  if Game.textinput then Game.textinput(t) end
end

-- Android back button is delivered as the Escape key by LÖVE.
function love.keyreleased(k)
  if k == "escape" and love.system.getOS() == "Android" and Game.androidBack then
    Game.androidBack(Net)
  end
end

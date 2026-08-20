local flux = require("libs/flux")
local Timer = require("libs/timer")
local ButtonManager = require("libs/simplebutton")

local Bowl = 
{
    x = 0,
    y = 0,
    ox = 0,
    oy = 0
}
Bowl.__index = Bowl
function Bowl.new(img, name, x, y)
    local bowl = setmetatable({}, Bowl)
    bowl.x = x or 0
    bowl.y = y or 0
    bowl.image = img
    bowl.name = name
    return bowl

end

local BowlsToPut

function love.load()
    BowlsToPut = 
    {
        Bowl.new(love.graphics.newImage("sprites/Bowl.png"), "LeftUpperBowl", 300, 200),
        Bowl.new(love.graphics.newImage("sprites/Bowl.png"), "LeftUBottomBowl", 300, 500),
        Bowl.new(love.graphics.newImage("sprites/Bowl.png"), "RightUpperBowl", 950, 200),
        Bowl.new(love.graphics.newImage("sprites/Bowl.png"), "RightUBottomBowl", 950, 500),

    }

end

function love.update()
    flux.update(dt)

end

function love.draw()
    for i, bowl in pairs(BowlsToPut) do
        if bowl ~= nil then
            love.graphics.draw(bowl.image, bowl.x, bowl.y, 0, 1, 1, bowl.image:getWidth()/2, bowl.image:getHeight()/2)
        end
    end
end
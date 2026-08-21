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

local Tomato = 
{
    x = 0,
    y = 0,
    ox = 0,
    oy = 0
}
Tomato.__index = Tomato
function Tomato.new(img, name, x, y) --maybe change name to id (number)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local tomato = setmetatable({}, Tomato)
    tomato.x = x or windowWidth/2
    tomato.y = y or windowHeight/2
    tomato.image = img
    tomato.name = name
    return tomato
end

local Tomatoes = {}
--timer
local countdownTime = 180 --in seconds
local timeLeft = countdownTime
local isTimerRunning = true
local ConstantSpawnInterval = 3 --in seconds
local SpawnInterval = ConstantSpawnInterval

local function TimerUpdate(dt) --later make timer for this game (adapt)
    if isTimerRunning then
        timeLeft = timeLeft - dt
        if timeLeft <= 0 then
            timeLeft = 0
            isTimerRunning = false
        end
    end

    if WinnerChosen and not isTimerRunning then
        breaktimeLeft = breaktimeLeft - dt
        if breaktimeLeft <= 0 then
            timeLeft = countdownTime
            isTimerRunning = true
        end
    end

end

local function SpawnTomato(dt)
    if SpawnInterval >= 0 then
        SpawnInterval = SpawnInterval - dt

    elseif SpawnInterval < 0 then
        table.insert(Tomatoes, Tomato.new(love.graphics.newImage("sprites/green_tomato.png"), "Green", 640, 360))
        SpawnInterval = ConstantSpawnInterval
    end

end

function love.load()
    BowlsToPut = 
    {
        Bowl.new(love.graphics.newImage("sprites/Bowl.png"), "LeftUpperBowl", 300, 200),
        Bowl.new(love.graphics.newImage("sprites/Bowl.png"), "LeftUBottomBowl", 300, 500),
        Bowl.new(love.graphics.newImage("sprites/Bowl.png"), "RightUpperBowl", 950, 200),
        Bowl.new(love.graphics.newImage("sprites/Bowl.png"), "RightUBottomBowl", 950, 500),

    }

end

function love.update(dt)
    flux.update(dt)
    TimerUpdate(dt)
    SpawnTomato(dt)

end

function love.draw()
    local minutes = math.floor(timeLeft / 60)
    local seconds = math.floor(timeLeft % 60)
    local timerText = string.format("Time: %02d:%02d", minutes, seconds)

    if isTimerRunning then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", 50, 50, 115, 25)
        love.graphics.setColor(255, 255, 255)
        love.graphics.print(timerText, 50, 50, 0, 1, 1) --timer

    end

    for i, bowl in pairs(BowlsToPut) do
        if bowl ~= nil then
            love.graphics.draw(bowl.image, bowl.x, bowl.y, 0, 1, 1, bowl.image:getWidth()/2, bowl.image:getHeight()/2)
        end
    end

    for i, tomato in pairs(Tomatoes) do
        if tomato ~= nil then
            love.graphics.draw(tomato.image, tomato.x, tomato.y, 0, 1, 1, tomato.image:getWidth()/2, tomato.image:getHeight()/2)
        end
    end
end
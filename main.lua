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

local ConstBowlCoords = 
{
    {x = 300, y = 200},
    {x = 300, y = 500},
    {x = 950, y = 200},
    {x = 950, y = 500}
}

local Tomato = 
{
    x = 0,
    y = 0,
    ox = 0,
    oy = 0
}
Tomato.__index = Tomato
function Tomato.new(img, id, x, y) --id = number of image .. length of tomatoes table .. constantSpawnInterval
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local tomato = setmetatable({}, Tomato)
    tomato.x = x or windowWidth/2
    tomato.y = y or windowHeight/2
    tomato.image = img
    tomato.id = id
    tomato.isDragging = false
    return tomato
end

--window and scenes (1 - menu, 2 - game)
local currentScene = 1
local VIRTUAL_WIDTH = 1280
local VIRTUAL_HEIGHT = 720
local scale = 1
local offsetX, offsetY = 0, 0

--rarely used functions
local toVirtualCoords
local closeEnough
local countTomatoes
local moveTomatoToBowl
local ShuffleBowls
local RemoveTomatoes
local isInsideButton
local LoopTheGame

--tomatoes
local Tomatoes = {}
local TomatoImages = {}
local TotalTomatoes = {}
--timers
local countdownTime = 60 --in seconds
local timeLeft = countdownTime
local isTimerRunning = true
local ConstantSpawnInterval = 2 --in seconds
local SpawnInterval = ConstantSpawnInterval
local clickTimer = 0
local breakTime = 5
local breaktimeLeft = breakTime
local ConstantminSpawnInterval = 1
local minSpawnInterval = ConstantminSpawnInterval

--text
local TotalTomatoCount

--menu UI
local startButton
local loopButton
local Background --maybe change later, because this one is AI generated
local LoopOffImage
local LoopOnImage

--game UI
local exitButton --button to exit to menu
local MenuButtons = {}
local GameButtons = {}

--bools
local AreTomatoesRemoved = false
local LoopIsOn = false


local function TimerUpdate(dt) --later make timer for this game (adapt)
    if isTimerRunning then
        timeLeft = timeLeft - dt
        if timeLeft <= 0 then
            timeLeft = 0
            isTimerRunning = false
        end

    elseif not isTimerRunning then
        ShuffleBowls()
        RemoveTomatoes()

        if LoopIsOn then
            breaktimeLeft = breaktimeLeft - dt
            if breaktimeLeft <= 0 then
                timeLeft = countdownTime
                isTimerRunning = true
                breaktimeLeft = breakTime
                AreTomatoesRemoved = false
                minSpawnInterval = ConstantSpawnInterval
                return
            end
        else
            timeLeft = countdownTime
            isTimerRunning = true
            breaktimeLeft = breakTime
            AreTomatoesRemoved = false
            minSpawnInterval = ConstantSpawnInterval
            currentScene = 1
        end
       
    end
end

local function SpawnTomato(dt)
    if not isTimerRunning then return end

    if SpawnInterval >= 0 then
        SpawnInterval = SpawnInterval - dt

    elseif SpawnInterval < 0 then
        local RandInt = love.math.random(1, 4)
        table.insert(Tomatoes, Tomato.new(TomatoImages[RandInt], (RandInt..#Tomatoes..ConstantSpawnInterval), (640 + love.math.random(-50, 50)), (360+ love.math.random(-50, 50))))
        SpawnInterval = love.math.random(1, ConstantSpawnInterval)
        minSpawnInterval = minSpawnInterval - love.math.random(0, 0.1)
    end

end

function love.load()
    startButton = ButtonManager.new("Start Game", VIRTUAL_WIDTH/2 - 50, VIRTUAL_HEIGHT/2 - 150, 150, 150)
    startButton:setAlignment('center')
    startButton:setLabel("")

    startButton:setImage(love.graphics.newImage("sprites/Play.png"))

    loopButton = ButtonManager.new("Loop Game", VIRTUAL_WIDTH - 200, 150, 150, 150)
    loopButton:setAlignment('center')
    loopButton:setLabel("")

    LoopOffImage = love.graphics.newImage("sprites/LoopOff.png")
    LoopOnImage = love.graphics.newImage("sprites/LoopOn.png")

    loopButton:setImage(LoopOffImage)
    MenuButtons = {startButton, loopButton}

    exitButton = ButtonManager.new("Exit Game", VIRTUAL_WIDTH/2, 50, 70, 70)
    exitButton:setAlignment('center')
    exitButton:setLabel("")
    exitButton:setImage(love.graphics.newImage("sprites/ExitButton.png"))

    GameButtons = {exitButton}

    Background = love.graphics.newImage("sprites/Background.png")

    BowlsToPut = 
    {
        Bowl.new(love.graphics.newImage("sprites/Green_Bowl.png"), "LeftUpperBowl", 300, 200),
        Bowl.new(love.graphics.newImage("sprites/Orange_Bowl.png"), "LeftBottomBowl", 300, 500),
        Bowl.new(love.graphics.newImage("sprites/Red_Bowl.png"), "RightUpperBowl", 950, 200),
        Bowl.new(love.graphics.newImage("sprites/Yellow_Bowl.png"), "RightUBottomBowl", 950, 500),
    }

    TomatoImages = 
    {
        love.graphics.newImage("sprites/green_tomato.png"),
        love.graphics.newImage("sprites/orange_tomato.png"),
        love.graphics.newImage("sprites/red_tomato.png"),
        love.graphics.newImage("sprites/yellow_tomato.png")
    }

end

function love.update(dt)
    flux.update(dt)
    ButtonManager.update(dt)

    if currentScene == 2 then
        if clickTimer > 0 then
            clickTimer = clickTimer - dt
        end
        TimerUpdate(dt)
        SpawnTomato(dt)

        for ing, tomato in pairs(Tomatoes) do
            if tomato.isDragging == true then
                local TomatoId = tonumber(string.sub(tostring(tomato.id:match("%d+")), 1, 1))
                if closeEnough(tomato.x, tomato.y, BowlsToPut[TomatoId].x, BowlsToPut[TomatoId].y, 100) then
                    moveTomatoToBowl(tomato)
                    countTomatoes(tomato)
                    tomato.isDragging = false --maybe change later
                    break
                end
    
                local MouseX, MouseY = toVirtualCoords(love.mouse.getX(), love.mouse.getY())
                tomato.x = MouseX - tomato.ox
                tomato.y = MouseY - tomato.oy
            end
        end
    end

    
end

function love.mousepressed(mx, my, button, istouch, presses)
    local mouseX, mouseY = toVirtualCoords(mx, my)

    if currentScene == 1 then
        if startButton and isInsideButton(mouseX, mouseY, startButton) then
            currentScene = 2
        end

        if loopButton and isInsideButton(mouseX, mouseY, loopButton) then
            LoopTheGame()
        end
    end

    local function CheckWhereClickedVegetable(PassedTable, scale)
        local toInsert = nil
        if clickTimer <= 0 then
            for tab, tomato in pairs(PassedTable) do
                local w = tomato.image:getWidth() * scale
                local h = tomato.image:getHeight() * scale

                local isClicked = mouseX >= tomato.x - w/2 and mouseX <= tomato.x + w/2
                            and mouseY >= tomato.y - h/2 and mouseY <= tomato.y + h/2

                if isClicked and tomato.isDragging == false then
                    tomato.isDragging = true
                    tomato.ox = mouseX - tomato.x
                    tomato.oy = mouseY - tomato.y
                    break
                end
            end

            if toInsert then
                table.insert(PassedTable, toInsert)
            end
        end
    end

    if button == 1 then
        CheckWhereClickedVegetable(Tomatoes, 1)

    end

    if exitButton and isInsideButton(mouseX, mouseY, exitButton) then
        print("hellow")
        timeLeft = countdownTime
        breaktimeLeft = breakTime
        minSpawnInterval = ConstantSpawnInterval
        RemoveTomatoes()
        AreTomatoesRemoved = false
        currentScene = 1

    end

end



function love.mousereleased(mx, my, button, istouch, presses)
    if button == 1 then
        for ing, tomato in pairs(Tomatoes) do
            if tomato.isDragging == true then
                tomato.isDragging = false
            end
        end 
    end
end


function love.draw()
    love.graphics.draw(Background, 0, 0)

    if currentScene == 1 then
        for _, btn in ipairs(MenuButtons) do
            btn:draw()
        end


    elseif currentScene == 2 then
        for _, btn in ipairs(GameButtons) do
            btn:draw()
        end

        local minutes
        local seconds
        local timerText
    
        if isTimerRunning then
            minutes = math.floor(timeLeft / 60)
            seconds = math.floor(timeLeft % 60)
            timerText = string.format("Time: %02d:%02d", minutes, seconds)

            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", 50, 50, 75, 20)
            love.graphics.setColor(255, 255, 255)
            love.graphics.print(timerText, 50, 50, 0, 1, 1) --timer
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", 1200, 50, 15, 15)
            love.graphics.setColor(255, 255, 255)
            love.graphics.print(tostring(#TotalTomatoes), 1200, 50, 0, 1, 1) --tomatoCount
        elseif not isTimerRunning then
            minutes = math.floor(breaktimeLeft / 60)
            seconds = math.floor(breaktimeLeft % 60)
            timerText = string.format("Time: %02d:%02d", minutes, seconds)

            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", 50, 50, 75, 20)
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
    
        for i, tomato in pairs(TotalTomatoes) do
            if tomato ~= nil then
                love.graphics.draw(tomato.image, tomato.x, tomato.y, 0, 1, 1, tomato.image:getWidth()/2, tomato.image:getHeight()/2)
            end
        end

    end

end

toVirtualCoords = function(screenX, screenY)
    local virtualX = (screenX - offsetX) / scale
    local virtualY = (screenY - offsetY) / scale

    virtualX = math.max(0, math.min(virtualX, VIRTUAL_WIDTH))
    virtualY = math.max(0, math.min(virtualY, VIRTUAL_HEIGHT))
    
    return virtualX, virtualY
end

closeEnough = function(x1, y1, x2, y2, maxDistance)
    local dx = x1 - x2
    local dy = y1 - y2
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < maxDistance
end

moveTomatoToBowl = function(tomato)
    local TomatoId = tonumber(string.sub(tostring(tomato.id:match("%d+")), 1, 1))
    tomato.x = BowlsToPut[TomatoId].x + love.math.random(0, 10)
    tomato.y = BowlsToPut[TomatoId].y + love.math.random(0, 10)
    
    for tab, tomato in ipairs(Tomatoes) do
        for i, slice in pairs(TotalTomatoes) do
            if slice.name == tomato.name and closeEnough(tomato.x, tomato.y, slice.x, slice.y, 100) then
                table.remove(Tomatoes, tab)
            end
        end
    end
end

countTomatoes = function(tomato)
    table.insert(TotalTomatoes, tomato)

end

ShuffleBowls = function()
    if not AreTomatoesRemoved then
        local NewBowlCoords = {}
        for i, coord in ipairs(ConstBowlCoords) do
            NewBowlCoords[i] = coord
        end

        print("Changing bowls")
        for b, bowl in pairs(BowlsToPut) do
            local NewCoords = love.math.random(1, #NewBowlCoords)
            bowl.x = NewBowlCoords[NewCoords].x
            bowl.y = NewBowlCoords[NewCoords].y
            table.remove(NewBowlCoords, NewCoords)
        end
    end
   
end

RemoveTomatoes = function()
    if not AreTomatoesRemoved then
        for i, slice in pairs(TotalTomatoes) do
            TotalTomatoes[i] = nil
        end
    
        for i, slice in pairs(Tomatoes) do
            Tomatoes[i] = nil
        end
        AreTomatoesRemoved = true
    end

end

isInsideButton = function (x, y, btn)
    return x >= btn.x and x <= btn.x + btn.width
       and y >= btn.y and y <= btn.y + btn.height
end

LoopTheGame = function()
    print("Hello")
    if LoopIsOn then
        loopButton:setImage(LoopOffImage)
        LoopIsOn = false
    elseif not LoopIsOn then
        loopButton:setImage(LoopOnImage)
        LoopIsOn = true
    end
end
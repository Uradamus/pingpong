--[[
Copyright (c) 2014 Uradamus

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
]]

function love.load()
    -- Uses hump's vector library. ( http://vrld.github.io/hump/ )
    Vector = require "vector"
    
    love.window.setTitle("Ping Pong")
    love.window.setMode(800, 600)
    love.graphics.setBackgroundColor(10, 20, 40)
    love.mouse.setVisible(false)
    
    -- Sounds generated with Bfxr. ( http://www.bfxr.net/ )
    bounce = love.audio.newSource("bounce.wav", "static")
    crash =  love.audio.newSource("crash.wav", "static")
    
    --[[ Text Image Quads ]]--
    -- Anonymous Pro font used for text graphics. ( http://www.marksimonson.com/fonts/view/anonymous-pro )
    img = love.graphics.newImage("text.png")
    numbers = {}
    for i = 0, 9, 1 do
        numbers[i+1] = love.graphics.newQuad(i*25, 0, 25, 36, 256, 128)
    end
    score_label = love.graphics.newQuad(115, 36, 137, 34, 256, 128)
    high_label = love.graphics.newQuad(0, 36, 112, 34, 256, 128)
    game_over_label = love.graphics.newQuad(0, 73, 219, 34, 256, 128)
    instruction_label = love.graphics.newQuad(0, 107, 244, 19, 256, 128)
    
    --[[ Starting values ]]--
    pause = true
    game_over = false
    
    pad_y = 290
    hit_step = 0
    miss_step = 0
    
    ball_pos = {}
    for i = 1, 4, 1 do
        ball_pos[i] = Vector(400, 325)
    end
    ball_vel = Vector(0, 0)
    start_vel = Vector(-1, 0)
    
    balls = 3
    points = 0
    point_array = {0, 0, 0, 0}
    
    -- High score file
    hs_file = love.filesystem.newFile("high_score.txt")
    hs_file:open("r")
    high_score = hs_file:read(all)
    hs_file:close()
    high_score = tonumber(high_score)
    if high_score == nil then
        high_score = 0
        hs_file:open("w")
        hs_file:write(high_score)
        hs_file:close()
    end
    high_array = {math.floor(high_score/1000), math.floor(high_score%1000/100), math.floor(high_score%100/10), 0}
end


function love.update(dt)
    --[[ Input ]]--
    if love.keyboard.isDown("w", "up") and (pad_y > 60) then
        pad_y = pad_y - 300 * dt
    end
    if love.keyboard.isDown("s", "down") and (pad_y < 520) then
        pad_y = pad_y + 300 * dt
    end
    if love.keyboard.isDown(" ") and ball_vel == Vector(0, 0) then
        pause = false
        if game_over == true then
            points = -10
            balls = 3
            score()
            game_over = false
        end
        start_vel = -start_vel
        ball_vel = start_vel
    end
    if love.keyboard.isDown("escape") then
        hs_file:open("w")
        hs_file:write(high_score)
        hs_file:close()
        love.event.quit()
    end
    
    --[[ Collision ]]--
    if ball_pos[4].y < 65 then
        ball_pos[4].y = 65
        ball_vel.y = -ball_vel.y
        love.audio.play(bounce)
    elseif ball_pos[4].y > 575 then
        ball_pos[4].y = 575
        ball_vel.y = -ball_vel.y
        love.audio.play(bounce)
    elseif ball_pos[4].x < -50 or ball_pos[4].x > 850 then
        balls = balls - 1
        miss_step = 20
        pause = true
        for i = 1, #ball_pos, 1 do
            ball_pos[i] = Vector(400, 320)
        end
        ball_vel = Vector(0, 0)
        love.audio.play(crash)
    elseif (ball_pos[4].x < 55 and ball_pos[4].x > 35) and (ball_pos[4].y > pad_y and ball_pos[4].y < pad_y + 60) then
        score()
        hit_step = 10
        ball_pos[4].x = 60
        ball_vel = Vector(1, (ball_pos[4].y-(pad_y+30))/15):normalized()
        if ball_vel.y == 0 then ball_vel.y = 0.01 end
        love.audio.play(bounce)
    elseif (ball_pos[4].x > 745 and ball_pos[4].x < 765) and (ball_pos[4].y > pad_y and ball_pos[4].y < pad_y + 60) then
        score()
        hit_step = 10
        ball_pos[4].x = 740
        ball_vel = Vector(-1, (ball_pos[4].y-(pad_y+30))/15):normalized()
        if ball_vel.y == 0 then ball_vel.y = 0.01 end
        love.audio.play(bounce)
    end
    
    --[[ Game Over ]]--
    if balls < 0 and game_over == false then
        hs_file:open("w")
        hs_file:write(high_score)
        hs_file:close()
        game_over = true
        pause = true
    end
    
    --[[ Position Ball ]]--
    local speed_inc = 20
    local speed = (200 + (math.floor(points / 50) * speed_inc)) * dt
    for i = 1, #ball_pos-1, 1 do
        ball_pos[i] = ball_pos[i+1]
    end
    ball_pos[4] = ball_pos[4] + ball_vel * speed
end


function love.draw()
    --[[ Borders ]]--
    miss()
    love.graphics.rectangle("fill", 0, 0, 800, 55)
    love.graphics.rectangle("fill", 0, 585, 800, 15)

    --[[ Pads ]]--
    hit()
    love.graphics.rectangle("fill", 40, pad_y, 10, 60)
    love.graphics.rectangle("fill", 750, pad_y, 10, 60)

    --[[ Ball ]]--
    for i = 1, #ball_pos, 1 do
        love.graphics.setColor(99, 143, 19, i*63.75)
        love.graphics.circle("fill", ball_pos[i].x, ball_pos[i].y, 10, 64)
    end

    --[[ Stats ]]--
    for i = 1, balls, 1 do
        love.graphics.circle("fill", i*35, 28, 15, 64)
    end
    
    if game_over == true then
        love.graphics.setColor(255, 0, 0)
        love.graphics.draw(img, game_over_label, 290, 150)
    end
    
    if pause == true then
        love.graphics.setColor(240, 235, 100)
        love.graphics.draw(img, instruction_label, 278, 200)
    end
    
    love.graphics.setColor(10, 20, 40)
    love.graphics.draw(img, score_label, 250, 11)
    love.graphics.draw(img, high_label, 570, 11)
    
    for i = 1, 4, 1 do
        love.graphics.draw(img, numbers[point_array[i]+1], 370+(i*25), 10)
        love.graphics.draw(img, numbers[high_array[i]+1], 665+(i*25), 10)
    end
end


function score()
    points = points + 10
    point_array = {math.floor(points/1000), math.floor(points%1000/100), math.floor(points%100/10), 0}
    
    if points > high_score then
        high_score = points
        high_array = point_array
    end
end


function miss()
    if miss_step > 0 then
        local n = love.math.random(1, 2)
        if n == 1 then
            love.graphics.setColor(255, 0, 0)
        else
            love.graphics.setColor(240, 240, 100)
        end
        miss_step = miss_step - 1
    else
        love.graphics.setColor(160, 170, 170)
    end
end


function hit()
    if hit_step > 0 then
        --love.graphics.setColor(240, 240, 100)
        -- 80, 70, -70
        love.graphics.setColor(160+(hit_step*8), 170+(hit_step*7), 170-(hit_step*7))
        hit_step = hit_step - 1
    end
end

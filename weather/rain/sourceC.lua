local screenX, screenY = guiGetScreenSize()

local rainConfig = {
    renderingRaindropsLimit = 50,
    rainDrops = {},
    rainSplashes = {},
    raining = false,
    timer = false,
    thunder = false,
    intensity = false,
    sound = false,
    soundSpeed = false,
    renderingRain = false,
    flashStartTick = false,
    rainSpeedMultiplier = 1.2,
}

local function stopSoundSlowly(soundElement)
    if not isElement(soundElement) then 
        return false 
    end

    local timerQuant = getSoundVolume(soundElement)

    setTimer(function()
        if not isElement(soundElement) then 
            return 
        end

        local soundVolume = getSoundVolume(soundElement)
        soundVolume = ((soundVolume * 10) - (0.1 * 10))/10
        setSoundVolume(soundElement, soundVolume - 0.05)

        if soundVolume > 0 then 
            return 
        end

        stopSound(soundElement)

        if isElement(soundElement) then 
            destroyElement(soundElement)
        end 
    end, 500, timerQuant * 10)
end

function setClientRainState(state, intensity)
    rainConfig.raining = state

    if rainConfig.raining then
        removeEventHandler("onClientRender", getRootElement(), renderClientRain)
        addEventHandler("onClientRender", getRootElement(), renderClientRain)

        if isTimer(rainConfig.timer) then
            killTimer(rainConfig.timer)
        end

        if isTimer(rainConfig.thunder) then
            killTimer(rainConfig.thunder)
        end 

        if intensity then 
            if isElement(rainConfig.sound) then
                destroyElement(rainConfig.sound)
            end

            if intensity == "light" then
                rainConfig.timer = setTimer(function() createClientRainDrop() end, 50, 0)
                rainConfig.sound = playSound("rain/raining.mp3", true)

                setSoundVolume(rainConfig.sound, 0.5)
            elseif intensity == "medium" then
                rainConfig.timer = setTimer(function() createClientRainDrop() end, 25, 0)
                rainConfig.sound = playSound("rain/raining.mp3", true)

                setSoundVolume(rainConfig.sound, 0.5)
            elseif intensity == "hard" then
                rainConfig.timer = setTimer(function() createClientRainDrop() end, 5, 0)
                rainConfig.sound = playSound("rain/raining.mp3", true)
                setSoundVolume(rainConfig.sound, 0.5)

                if isTimer(rainConfig.thunder) then
                    killTimer(rainConfig.thunder)
                end

                clientStartLightningSounds()
            end

            setRainLevel(0)
            rainConfig.intensity = intensity
            rainConfig.renderingRain = true
        else
            rainConfig.timer = setTimer(function() createClientRainDrop() end, 5, 0)
        end

        setSkyGradient(50, 50, 50, 50, 50, 50)
    else
        if isTimer(rainConfig.thunder) then
            killTimer(rainConfig.thunder)
        end

        if isTimer(rainConfig.timer) then
            killTimer(rainConfig.timer)
        end

        stopSoundSlowly(rainConfig.thunder)
        stopSoundSlowly(rainConfig.sound)

        removeEventHandler("onClientRender", getRootElement(), renderClientRain)
        resetSkyGradient()

        rainConfig.renderingRain = false
    end
end

addEvent("setClientRainState", true)
addEventHandler("setClientRainState", getResourceRootElement(), setClientRainState)

function createClientRainDrop()
    if rainConfig.raining and rainConfig.renderingRain then
        local camX, camY, camZ, lookX, lookY, lookZ = getCameraMatrix()

        local dirX = lookX - camX
        local dirY = lookY - camY
        local len = math.sqrt(dirX*dirX + dirY*dirY)

        if len == 0 then 
            return 
        end

        dirX, dirY = dirX/len, dirY/len

        local pX, pY, pZ = getElementPosition(localPlayer)

        local spread = 13
        local offsetX = (math.random() - 0.5) * spread
        local offsetY = (math.random() - 0.5) * spread

        local dropX = pX + dirX * 5 + offsetX
        local dropY = pY + dirY * 5 + offsetY
        local dropZ = pZ + 10

        local hit, hitX, hitY, hitZ = processLineOfSight(
            dropX, dropY, dropZ,
            dropX, dropY, dropZ - 20,
            true, false, false, true, false, false, false, false
        )

        if not hit then
            hitX, hitY, hitZ = dropX, dropY, dropZ - 20
        end

        if rainConfig.intensity == "light" then 
            dropSpeed = math.random(300, 500)
            dropLength = 0.2 + math.random() * (0.5 - 0.2)
        elseif rainConfig.intensity == "medium" then 
            dropSpeed = math.random(100, 300)
            dropLength = 0.5 + math.random() * (0.5 - 0.2)
        elseif rainConfig.intensity == "hard" then 
            dropSpeed = math.random(10, 100)
            dropLength = 1 + math.random() * (0.5 - 0.2)
        end

        table.insert(rainConfig.rainDrops, {
            x = dropX,
            y = dropY,
            z = dropZ,
            endZ = hitZ,
            dropTick = getTickCount(),
            speed = dropSpeed * rainConfig.rainSpeedMultiplier,
            alpha = 100,
            length = dropLength
        })

        if hit then
            local splash = createEffect("water_swim", hitX, hitY, hitZ)
            table.insert(rainConfig.rainSplashes, {effect = splash})

            if #rainConfig.rainSplashes > rainConfig.renderingRaindropsLimit then
                if rainConfig.rainSplashes[1] and isElement(rainConfig.rainSplashes[1].effect) then
                    destroyElement(rainConfig.rainSplashes[1].effect)
                end
                table.remove(rainConfig.rainSplashes, 1)
            end
        end
    end
end

function renderClientRain()
    if not rainConfig.renderingRain then
        return
    end

    for i = 1, #rainConfig.rainDrops do 
        if rainConfig.rainDrops[i] then
            local drop = rainConfig.rainDrops[i]
            local progress = (getTickCount() - drop.dropTick) / drop.speed

            if not rainConfig.raining then
                removeEventHandler("onClientRender", root, renderClientRain)
            end

            if #rainConfig.rainDrops > rainConfig.renderingRaindropsLimit then
                table.remove(rainConfig.rainDrops, 1)
            end

            if progress >= 1 then
                table.remove(rainConfig.rainDrops, i)
            else
                local z = interpolateBetween(drop.z, 0, 0, drop.endZ + 2, 0, 0, progress, "Linear")
                dxDrawLine3D(drop.x, drop.y, z, drop.x, drop.y, z - drop.length, tocolor(230, 230, 230, 50), 1)
            end
        end
    end
end

function clientThunderFlash()
    local elapsed = getTickCount() - rainConfig.flashStartTick

    if elapsed >= 200 then
        rainConfig.flashStartTick = nil
        removeEventHandler("onClientRender", root, clientThunderFlash)

        return
    end

    local alpha = 200 * (1 - elapsed / 200)
    dxDrawRectangle(0, 0, screenX, screenY, tocolor(200, 200, 200, alpha), true)
end

function flashClientScreen()
    if rainConfig.flashStartTick then 
        return 
    end 

    rainConfig.flashStartTick = getTickCount()

    removeEventHandler("onClientRender", getRootElement(), clientThunderFlash)
    addEventHandler("onClientRender", getRootElement(), clientThunderFlash)
end

function clientStartLightningSounds()
    local interval = math.random(30000, 60000)

    rainConfig.thunder = setTimer(function()
        local sound = "rain/thunder" .. math.random(1, 3) .. ".mp3"

        if rainConfig.renderingRain then
            local strike = playSound(sound)
            setSoundVolume(strike, 0.5)
            flashClientScreen()
        end

        clientStartLightningSounds()
    end, interval, 1)
end

addEventHandler("onClientElementInteriorChange", localPlayer, 
    function(oldInterior, newInterior)
        if rainConfig.raining then
            rainConfig.renderingRain = newInterior == 0 and true or false

            if not rainConfig.renderingRain then
                if isElement(rainConfig.sound) then
                    setSoundVolume(rainConfig.sound, 0)
                end
            else
                if isElement(rainConfig.sound) then
                    setSoundVolume(rainConfig.sound, 0.5)
                end
            end
        end
    end
)

addEventHandler("onClientElementDimensionChange", localPlayer, 
    function(oldDimension, newDimension)
        if rainConfig.raining then
            rainConfig.renderingRain = newDimension == 0 and true or false

            if not rainConfig.renderingRain then
                if isElement(rainConfig.sound) then
                    setSoundVolume(rainConfig.sound, 0)
                end
            else
                if isElement(rainConfig.sound) then
                    setSoundVolume(rainConfig.sound, 0.5)
                end
            end
        end
    end
)


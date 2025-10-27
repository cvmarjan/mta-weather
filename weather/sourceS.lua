local weatherChangeMinuteInterval = 30
local currentWeather = false
local weatherChangeTimer = false
local nextWeatherCicle = false
local weatherProperties = {}

local weatherTable = {
    [1] = {
        event = false,
        defaultWeatherID = 0,
        name = "sunny",
    },

    [2] = {
        event = false,
        defaultWeatherID = 7,
        name = "cloudy",
    },

    [3] = {
        event = "setClientRainState",
        defaultWeatherID = 7,
        name = "rainy",
        intensity = {"light", "medium", "hard"},
    },
}

local function smoothWeatherChange(targetWeather, duration)
    local steps = 10
    local delay = duration/steps
    local currentStep = 0
    local timer

    timer = setTimer(function()
        currentStep = currentStep + 1
        if currentStep >= steps then
            killTimer(timer)
            setWeather(targetWeather)
        else
            setWeatherBlended(targetWeather)
        end
    end, delay * 1000, steps)
end

function setServerWeather(id)
    if isTimer(weatherChangeTimer) then
        killTimer(weatherChangeTimer)
    end

    if id then
        weatherIndex = id
    else
        weatherIndex = not nextWeatherCicle and math.random(1, #weatherTable) or nextWeatherCicle
    end

    local weather = weatherTable[weatherIndex]

    if weatherIndex == 1 then 
        triggerClientEvent("setClientRainState", getRootElement(), false)
    elseif weatherIndex == 2 then 
        triggerClientEvent("setClientRainState", getRootElement(), false)
    elseif weatherIndex == 3 then 
        selectIntensity = weather.intensity[math.random(1, #weather.intensity)]
        triggerClientEvent("setClientRainState", getResourceRootElement(), true, selectIntensity)
    end

    if weather.defaultWeatherID then
        smoothWeatherChange(weather.defaultWeatherID, 5)
    end

    currentWeather = {
        id = weatherIndex,
        defaultWeatherID = weather.defaultWeatherID,
        intensity = weatherIndex == 3 and selectIntensity or false
    }

    local api = "https://api.open-meteo.com/v1/forecast?latitude=34.0522&longitude=-118.2437&current_weather=true"

    fetchRemote(api,
        function(data)
            local result = fromJSON(data)
            local temp = result.current_weather.temperature
            local wind = result.current_weather.windspeed
            nextWeatherCicle = math.random(1, #weatherTable)

            outputChatBox("[Weather Forecast] #ffffffThe current weather is " .. weather.name, root, 58, 114, 228, true)
            outputChatBox("[Weather Forecast] #ffffffTemperature, wind strength: " .. temp .. " °C, " .. wind .. " km/h", root, 58, 114, 228, true)
            outputChatBox("[Weather Forecast] #ffffffIn one hour: " .. weatherTable[nextWeatherCicle].name .. " weather expected", root, 58, 114, 228, true)
        
            weatherProperties = {
                name = weather.name,
                temperature = temp,
                wind = wind,
                next = weatherTable[nextWeatherCicle].name,
            }
        end,
    nil, true)

    weatherChangeTimer = setTimer(function()
        setServerWeather()
    end, weatherChangeMinuteInterval * 60000, 0)
end

addCommandHandler("changeweather", 
    function(client, command, id)
        if not tonumber(id) then 
            return outputChatBox("[Weather]#ffffff The weather can only be a number! (1 - " .. #weatherTable .. ")", client, 250, 99, 70, true)
        end

        if tonumber(id) > #weatherTable then
            return outputChatBox("[Weather]#ffffff Not valid weather ID! (1 - " .. #weatherTable .. ")", client, 250, 99, 70, true)
        end

        setServerWeather(tonumber(id))
    end
)

function loadWeatherToClient(client)
    if currentWeather then 
        if currentWeather.id == 1 then 
            triggerClientEvent(client, "setClientRainState", getRootElement(), false)
        elseif currentWeather.id == 2 then 
            triggerClientEvent(client, "setClientRainState", getRootElement(), false)
        elseif currentWeather.id == 3 then 
            triggerClientEvent(client, "setClientRainState", getResourceRootElement(), true, currentWeather.intensity)
        end

        if currentWeather.defaultWeatherID then
            smoothWeatherChange(currentWeather.defaultWeatherID, 5)
        end

        if weatherProperties then 
            outputChatBox("[Weather Forecast] #ffffffThe current weather is " .. weather.name, client, 58, 114, 228, true)
            outputChatBox("[Weather Forecast] #ffffffTemperature, wind strength: " .. temp .. " °C, " .. wind .. " km/h", client, 58, 114, 228, true)
            outputChatBox("[Weather Forecast] #ffffffIn one hour: " .. weatherTable[nextWeatherCicle].name .. " weather expected", client, 58, 114, 228, true)
        end
    end
end

addEventHandler("onPlayerJoin", getRootElement(), 
    function()
        loadWeatherToClient(source)
    end
)

addEventHandler("onResourceStart", getResourceRootElement(), 
    function()
        setTimer(function()
            setServerWeather()
        end, 500, 1)

        setMinuteDuration(10000)
    end
)



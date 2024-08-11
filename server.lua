QBCore = exports['qb-core']:GetCoreObject()

local playerCodes = {}

local function generateCode()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local code = ""
    for i = 1, 6 do
        local randomIndex = math.random(1, #charset)
        code = code .. charset:sub(randomIndex, randomIndex)
    end
    return code
end

local function assignNewCodes()
    for _, playerId in ipairs(GetPlayers()) do
        playerId = tonumber(playerId)
        playerCodes[playerId] = {
            code = generateCode(),
            claimed = false
        }
        TriggerClientEvent('chat:addMessage', playerId, {color = { 255, 0, 0},args = {"Paycheck", "รหัส paycheck ของคุณคือ: " .. playerCodes[playerId].code}})
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.Time * 1000)
        local allCodesClaimed = true
        for _, data in pairs(playerCodes) do
            if not data.claimed then
                allCodesClaimed = false
                break
            end
        end
        if allCodesClaimed then
            assignNewCodes()
        end
    end
end)



QBCore.Commands.Add('paycheck', 'กรอกรหัสเพื่อรับเงิน', {{name = 'code', help = 'รหัส paycheck'}}, true, function(source, args)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local inputCode = args[1]
    local playerId = source
    local playerLicense

    for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
        if string.sub(identifier, 1, string.len("license:")) == "license:" then
            playerLicense = identifier
            break
        end
    end

    if playerCodes[playerId] and inputCode == playerCodes[playerId].code then
        if not playerCodes[playerId].claimed then
            local moneyToAdd = Config.Money

            if Config.SpecialPlayers[playerLicense] then
                moneyToAdd = Config.SpecialPlayers[playerLicense]
            end

            xPlayer.Functions.AddMoney('bank', moneyToAdd)
            playerCodes[playerId].claimed = true
            TriggerClientEvent('chat:addMessage', playerId, {args = {'^2[PAYCHECK]^0 คุณได้รับเงิน ^2' .. moneyToAdd .. '$'}})
        else
            TriggerClientEvent('chat:addMessage', playerId, {args = {'^1[!]^0 คุณได้ทำการกรอกรหัสไปแล้ว'}})
        end
    else
        TriggerClientEvent('chat:addMessage', playerId, {args = {'^1[!]^0 รหัสไม่ถูกต้อง'}})
    end
end)


QBCore.Commands.Add('mypaycheck', 'ดูรหัส paycheck ของคุณ', {}, false, function (source)
    local playerId = source
    if playerCodes[playerId] and not playerCodes[playerId].claimed then
        TriggerClientEvent('chat:addMessage', playerId, {color = { 255, 0, 0}, args = {"Mypaycheck^0:" .. playerCodes[playerId].code}})
    else
        TriggerClientEvent('chat:addMessage', playerId, {args = {'^1[!]^0 คุณไม่มีรหัส paycheck ที่ยังไม่ได้ใช้'}})
    end
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    playerCodes[playerId] = nil
end)

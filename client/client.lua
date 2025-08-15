local MoneyWash = {
    startWashing = false,
    timeWashing = false,
    currentWashAmount = 0,
    cfg = cfg
}

function MoneyWash:getTimeWashing()
    self.timeWashing = true
    Wait(self.cfg.waitRewashing)
    self.timeWashing = false
end

function MoneyWash:createBlip(coords, sprite, name)
    if not coords or not sprite or not name then return end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function MoneyWash:startWashingMoney()
    if self.startWashing then lib.notify({ title = locale('title_notify'), description = locale('description_start_wash'), type = locale('error_notify') }) return end
    if self.timeWashing then lib.notify({ title = locale('title_notify'), description = locale('description_time_wash'), type = locale('error_notify') }) return end
    local blackMoney = exports.ox_inventory:Search('count', 'black_money')
    if blackMoney <= 0 then lib.notify({ title = locale('title_notify'), description = locale('description_no_black_money'), type = 'error' }) return end

    local input = lib.inputDialog(locale('title_menu_dialog'), {
        { type = 'number', label = locale('label_dialog'), min = 1, max = blackMoney, description = locale('description_dialog'), icon = self.cfg.iconDialog }
    })

    if not input then return end

    self.currentWashAmount = tonumber(input[1])
    TriggerServerEvent('krs_moneywash:washAmount', self.currentWashAmount)
end

RegisterNetEvent('krs_moneywash:startWashing', function(amount)
    local playerPed = cache.ped
    MoneyWash.startWashing = true
    lib.notify({ title = locale('title_notify'), description = locale('description_start_washing'), type = locale('inform_notify') })
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_AA_SMOKE")
    if lib.progressCircle({
        duration = MoneyWash.cfg.washDuration,
        position = MoneyWash.cfg.positionProgress,
        label = locale('label_progress'),
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true }
    }) then
        lib.notify({ title = locale('title_notify'), description = locale('description_finish_wash'), type = locale('inform_notify') })
    end
    MoneyWash.startWashing = false
    ClearPedTasksImmediately(playerPed)
    MoneyWash:getTimeWashing()
end)

function MoneyWash:initialize()
    for _, v in pairs(self.cfg.positionWashing) do
        if v.active then self:createBlip(v.coords, v.sprite, v.name) end
        lib.zones.sphere({
            coords = v.coords,
            size = vec3(1.6, 1.4, 3.2),
            rotation = 346.25,
            debug = false,
            onExit = function() lib.hideTextUI() end,
            onEnter = function() lib.showTextUI(locale('enter_textui')) end,
            inside = function(self)
                DrawMarker(0, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 255, false, true, 2, false, nil, nil, false)
                if IsControlJustReleased(0, 38) then MoneyWash:startWashingMoney() end
            end
        })
    end
end

MoneyWash:initialize()

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    MoneyWash:initialize()
end)

MoneyWash.cfg = cfg
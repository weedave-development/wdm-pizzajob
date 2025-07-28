local pizzaJobActive = false
local deliveryBlip = nil
local deliveryVehicle = nil
local deliveryCount = 0
local cooldownActive = false
local returningVehicle = false

local deliveryLocations = { -- Make sure 10 different locations is on here only, no more, no less otherwise it wont work!
   {x = 73.71, y = -1937.68, z = 20.0},
  {x = 129.83, y = -1854.5, z = 23.9},
 {x = 171.28, y = -1871.34, z = 23.4},
{x = 405.85, y = -1751.11, z = 28.71},
{x = 373.83, y = 427.87, z = 144.68},
{x = 57.5, y = 449.59, z = 146.07},
{x = -230.37, y = 488.35, z = 127.77},
{x = 151.6, y = -72.87, z = 66.67},
{x = 320.61, y = -1759.8, z = 28.64},
{x = 405.43, y = -1795.76, z = 28.09}
}

local availableLocations = {}

local pizzaShop = {x = 538.34, y = 101.71, z = 96.53} -- Pizza shop location

CreateThread(function()
    local blip = AddBlipForCoord(pizzaShop.x, pizzaShop.y, pizzaShop.z)
    SetBlipSprite(blip, 267)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza Job")
    EndTextCommandSetBlipName(blip)
end)

local function resetAvailableLocations()
    availableLocations = {}
    for i = 1, #deliveryLocations do
        table.insert(availableLocations, i)
    end
end

RegisterNetEvent('wdm-pizzajob:client:startJob', function()
    pizzaJobActive = true
    deliveryCount = 0
    returningVehicle = false
    resetAvailableLocations()
    if not deliveryVehicle or not DoesEntityExist(deliveryVehicle) then
        local vehicleHash = GetHashKey('faggio')
         exports.qbx_core:Notify("Take your vehicle and head to the delivery locations! Hurry!", "info")
        RequestModel(vehicleHash)
        while not HasModelLoaded(vehicleHash) do Wait(10) end
        vec3(535.54, 96.54, 96.34)
        deliveryVehicle = CreateVehicle(vehicleHash, 535.54, 96.54, 96.34, 0.0, true, false)
        -- Give keys to player
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(deliveryVehicle))
    end
    StartNextDelivery()
end)

function StartNextDelivery()
    if not pizzaJobActive then return end
    if deliveryCount >= 10 then
        returningVehicle = true
        if deliveryBlip then RemoveBlip(deliveryBlip) end
        exports.qbx_core:Notify("You've finished your deliveries! Return your vehicle to the pizza shop.", "info")
        SetNewWaypoint(pizzaShop.x, pizzaShop.y)
        return
    end

    -- This picks a random unused location
    local idx = math.random(#availableLocations)
    local locIndex = availableLocations[idx]
    table.remove(availableLocations, idx)
    local loc = deliveryLocations[locIndex]

    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipSprite(deliveryBlip, 280)
    SetBlipColour(deliveryBlip, 5)
    SetBlipScale(deliveryBlip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Pizza Delivery")
    EndTextCommandSetBlipName(deliveryBlip)
    SetNewWaypoint(loc.x, loc.y)

    -- Spawn ped at location
    local pedModel = `a_f_m_fatwhite_01`
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(10) end
    local deliveryPed = CreatePed(4, pedModel, loc.x, loc.y, loc.z, loc.heading, false, true)
    SetEntityAsMissionEntity(deliveryPed, true, true)
    FreezeEntityPosition(deliveryPed, true)
    SetBlockingOfNonTemporaryEvents(deliveryPed, true)

    local showingDeliveryText = false
    CreateThread(function()
        while pizzaJobActive and not returningVehicle do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local pedCoords = GetEntityCoords(deliveryPed)
            if #(coords - pedCoords) < 2.0 then
                if not showingDeliveryText then
                    lib.showTextUI('[E] Deliver Pizza')
                    showingDeliveryText = true
                end
                if IsControlJustReleased(0, 38) then -- E
                    lib.hideTextUI()
                    showingDeliveryText = false
                    RemoveBlip(deliveryBlip)
                    TriggerServerEvent('wdm-pizzajob:server:pay')
                    deliveryCount = deliveryCount + 1

                    -- Make ped walk away and despawn
                    FreezeEntityPosition(deliveryPed, false)
                    TaskGoStraightToCoord(deliveryPed, pedCoords.x + 10.0, pedCoords.y, pedCoords.z, 1.0, -1, 0.0, 0.0)
                    Wait(3000)
                    DeleteEntity(deliveryPed)

                    Wait(1000)
                    StartNextDelivery() -- Start another delivery or return vehicle
                    break
                end
            else
                if showingDeliveryText then
                    lib.hideTextUI()
                    showingDeliveryText = false
                end
            end
        end
        if showingDeliveryText then
            lib.hideTextUI()
        end
        if deliveryPed and DoesEntityExist(deliveryPed) then
            DeleteEntity(deliveryPed)
        end
    end)
end

-- Start/stop job UI at pizza shop
local showingStartText, showingStopText, showingReturnText = false, false, false
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        -- Start job
        if #(coords - vector3(pizzaShop.x, pizzaShop.y, pizzaShop.z)) < 2.0 and not pizzaJobActive and not cooldownActive then
            DrawMarker(2, pizzaShop.x, pizzaShop.y, pizzaShop.z+1, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 100, false, true, 2, nil, nil, false)
            if not showingStartText then
                lib.showTextUI('[E] Start Pizza Job')
                showingStartText = true
            end
            if IsControlJustReleased(0, 38) then -- E
                lib.hideTextUI()
                showingStartText = false
                TriggerServerEvent('wdm-pizzajob:server:startJob')
            end
        else
            if showingStartText then
                lib.hideTextUI()
                showingStartText = false
            end
        end
        -- Stop job (manual stop, optional)
        if #(coords - vector3(pizzaShop.x, pizzaShop.y, pizzaShop.z)) < 2.0 and pizzaJobActive and not returningVehicle then
            DrawMarker(2, pizzaShop.x, pizzaShop.y, pizzaShop.z+1, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 0, 0, 100, false, true, 2, nil, nil, false)
            if not showingStopText then
                lib.showTextUI('[E] Stop Pizza Job')
                showingStopText = true
            end
            if IsControlJustReleased(0, 38) then -- E
                lib.hideTextUI()
                showingStopText = false
                pizzaJobActive = false
                if deliveryBlip then RemoveBlip(deliveryBlip) end
                if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
                    DeleteEntity(deliveryVehicle)
                end
                exports.qbx_core:Notify("You have stopped the pizza job.", "error")
            end
        else
            if showingStopText then
                lib.hideTextUI()
                showingStopText = false
            end
        end
        -- Asked to Return vehicle after 10 deliveries, no more deliveries
        if #(coords - vector3(pizzaShop.x, pizzaShop.y, pizzaShop.z)) < 3.0 and pizzaJobActive and returningVehicle then
            DrawMarker(2, pizzaShop.x, pizzaShop.y, pizzaShop.z+1, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 0, 255, 100, false, true, 2, nil, nil, false)
            if not showingReturnText then
                lib.showTextUI('[E] Return Vehicle & Finish Job')
                showingReturnText = true
            end
            if IsControlJustReleased(0, 38) then -- E
                lib.hideTextUI()
                showingReturnText = false
                pizzaJobActive = false
                returningVehicle = false
                if deliveryBlip then RemoveBlip(deliveryBlip) end
                if deliveryVehicle and DoesEntityExist(deliveryVehicle) then
                    DeleteEntity(deliveryVehicle)
                end
                exports.qbx_core:Notify("Thank you for your work! You can do more deliveries after a break.", "success")
                wait (2000)
                  exports.qbx_core:Notify("For returning my car, Here is a bonus payment out $50!", "success")
                    TriggerServerEvent('wdm-pizzajob:server:bonuspay')
            end
        else
            if showingReturnText then
                lib.hideTextUI()
                showingReturnText = false
            end
        end
    end
end)
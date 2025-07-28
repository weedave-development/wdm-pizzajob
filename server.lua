RegisterNetEvent('wdm-pizzajob:server:startJob', function()
    local src = source
    TriggerClientEvent('wdm-pizzajob:client:startJob', src)
end)

RegisterNetEvent('wdm-pizzajob:server:pay', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if Player then
        exports.qbx_core:AddMoney(source, 'cash', math.random(100, 250), "Pizza Delivery Payment")
    end
end)

RegisterNetEvent('wdm-pizzajob:server:bonuspay', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if Player then
        exports.qbx_core:AddMoney(source, 'cash', 50, "Pizza Delivery Bonus")
    end
end)

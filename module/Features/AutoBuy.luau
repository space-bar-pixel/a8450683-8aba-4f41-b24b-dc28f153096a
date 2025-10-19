local AutoBuy = {}

function AutoBuy.mount(ctx)

    local mounted = {}
    function mounted:Destroy() end
    return mounted
end

return AutoBuy

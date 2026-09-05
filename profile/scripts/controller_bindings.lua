--[[
    RSDWVR - controller_bindings.lua

    DISABLED. vr:get_action_handle()/is_action_active() throw something
    that even a Lua pcall around the call site can't catch in this UEVR
    build - the error surfaces from UEVR's own outer handler around the
    whole on_xinput_get_state callback instead ("Exception in
    on_xinput_get_state"), meaning it's very likely a raw C++/SEH
    exception rather than a Lua-catchable error, regardless of the action
    name given. Turns out unnecessary anyway: physical Y already reaches
    the game fine via UEVR's default mapping (confirmed - it opens the
    spell menu), so the default virtual-gamepad pipeline works; we just
    don't yet know which physical input is bound to Inventory specifically.
    Left empty until we find a working mechanism or confirm one isn't
    needed.
]]

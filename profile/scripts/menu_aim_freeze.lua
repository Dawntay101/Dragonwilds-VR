--[[
    RSDWVR - menu_aim_freeze.lua

    Head-aim (VR_AimMethod=1 + VR_AimModifyPlayerControlRotation=true,
    see README "First-person mode") writes the HMD's rotation into the
    PlayerController's ControlRotation every frame with no smoothing.
    That's also the same value UEVR's automatic 3D-projected UI uses to
    orient menus/HUD, so menus end up re-centering on your gaze
    instantly and become unreadable ("moving out of the way").

    There's no separate cvar to decouple menu placement from aim - both
    read the same ControlRotation. This script works around it with a
    manual hold-to-freeze: hold Left Stick Click (L3) to temporarily
    suspend head-aim (vr:set_aim_allowed(false), which UEVR treats the
    same as AimMethod=Game - ControlRotation stops being overwritten by
    head tracking, so the menu holds still while you read it), release
    to resume. Uses the raw XInput polling callback (on_xinput_get_state)
    rather than the action-handle API (get_action_handle/is_action_active),
    which throws an uncatchable exception in this build - see
    controller_bindings.lua.

    L3 is unused by Dragonwilds' native control scheme (see README
    control table), so this doesn't take over an existing action. L3+R3
    together also briefly triggers this (since L3 is part of that combo)
    while opening UEVR's own overlay - harmless, unrelated to the game's
    own menus.

    Untested in-headset - first thing to verify is whether holding L3
    actually keeps the menu still; if L3 is awkward to hold while also
    navigating a menu with the right stick, a different held button (or
    a toggle instead of hold) is an easy change here.
]]

local vr = uevr.params.vr

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local held = (state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB) ~= 0
    vr:set_aim_allowed(not held)
end)

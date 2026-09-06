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
    manual hold-to-freeze: hold Left Stick Click (L3) *and* the left
    grip/squeeze button at the same time to temporarily suspend head-aim
    (vr:set_aim_allowed(false), which UEVR treats the same as
    AimMethod=Game - ControlRotation stops being overwritten by head
    tracking, so the menu holds still while you read it), release either
    to resume. A single-button hold (just L3) was tried first and
    dropped - one thumb button alone was awkward to hold steady while
    also moving the same thumbstick to navigate a menu, and a two-button
    chord is much less likely to be triggered by accident. Uses the raw
    XInput polling callback (on_xinput_get_state) rather than the
    action-handle API (get_action_handle/is_action_active), which throws
    an uncatchable exception in this build - see controller_bindings.lua.

    UEVR's default Touch-controller mapping puts the left grip on
    XINPUT_GAMEPAD_LEFT_SHOULDER (LB), which Dragonwilds' native control
    scheme already uses for Quick Access (see README control table) -
    unlike L3, which is unused. So while the L3+LB chord is held, this
    script also masks the LB bit out of the reported gamepad state
    before the game sees it, to stop Quick Access from popping open
    every time the chord is used to freeze aim for a menu. LB still
    works normally for Quick Access when L3 isn't also held. L3+R3
    together also briefly triggers this (since L3 is part of that combo)
    while opening UEVR's own overlay - harmless, unrelated to the game's
    own menus.

    Untested in-headset - first thing to verify is whether holding this
    two-button chord actually keeps the menu still, and whether it's
    comfortable to hold while navigating a menu with the same hand's
    thumbstick.
]]

local vr = uevr.params.vr

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local buttons = state.Gamepad.wButtons
    local l3_held = (buttons & XINPUT_GAMEPAD_LEFT_THUMB) ~= 0
    local lb_held = (buttons & XINPUT_GAMEPAD_LEFT_SHOULDER) ~= 0
    local chord_held = l3_held and lb_held

    vr:set_aim_allowed(not chord_held)

    if chord_held then
        state.Gamepad.wButtons = buttons & ~XINPUT_GAMEPAD_LEFT_SHOULDER
    end
end)

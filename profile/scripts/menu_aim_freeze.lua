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
    toggle: press Left Stick Click (L3) *and* the left grip/squeeze
    button together (a chord, not a hold) to flip head-aim off
    (vr:set_aim_allowed(false), which UEVR treats the same as
    AimMethod=Game - ControlRotation stops being overwritten by head
    tracking, so the menu holds still while you read it); press the
    same chord again to flip it back on. A plain hold (of L3 alone,
    then of the L3+grip chord) was tried first and dropped both times -
    awkward to hold steady with the same hand that also has to move the
    stick to navigate a menu - so this edge-detects the chord instead
    and toggles a persistent `frozen` flag rather than tracking
    press-state directly. Uses the raw XInput polling callback
    (on_xinput_get_state) rather than the action-handle API
    (get_action_handle/is_action_active), which throws an uncatchable
    exception in this build - see controller_bindings.lua.

    UEVR's default Touch-controller mapping puts the left grip on
    XINPUT_GAMEPAD_LEFT_SHOULDER (LB), which Dragonwilds' native control
    scheme already uses for Quick Access (see README control table) -
    unlike L3, which is unused. So whenever both chord buttons are
    simultaneously held (i.e. during the toggle press itself), this
    script also masks the LB bit out of the reported gamepad state
    before the game sees it, to stop that same press from opening Quick
    Access. LB still works normally on its own, without L3. L3+R3
    together also briefly triggers this (since L3 is part of that combo)
    while opening UEVR's own overlay - harmless, unrelated to the game's
    own menus.

    Untested in-headset - first report (2026-09-05) was that the chord
    does nothing. Traced through UEVR's own source
    (src/mods/VR.cpp/.hpp, src/mods/vr/IXRTrackingSystemHook.cpp,
    src/mods/vr/OverlayComponent.cpp) to confirm set_aim_allowed(false)
    really does gate every head-aim code path via a single
    is_any_aim_method_active() check, and that grip really is
    XINPUT_GAMEPAD_LEFT_SHOULDER, and that mods run in an order
    (VR before LuaLoader) where our button reads see real state and our
    LB mask isn't undone afterward - all consistent with this working.
    So the C++ side looks right; added logging below (only on state
    changes, not every frame) to see from the next log.txt whether the
    chord is even being detected as pressed, and whether the toggle
    fires, before guessing further blind.
]]

local vr = uevr.params.vr
local log = uevr.params.functions

local function debug(msg)
    log:log_info("[menu_aim_freeze] " .. msg)
end

local frozen = false
local chord_was_held = false
local l3_was_held = false
local lb_was_held = false

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local buttons = state.Gamepad.wButtons
    local l3_held = (buttons & XINPUT_GAMEPAD_LEFT_THUMB) ~= 0
    local lb_held = (buttons & XINPUT_GAMEPAD_LEFT_SHOULDER) ~= 0
    local chord_held = l3_held and lb_held

    if l3_held ~= l3_was_held then
        debug("L3 " .. (l3_held and "pressed" or "released"))
        l3_was_held = l3_held
    end

    if lb_held ~= lb_was_held then
        debug("LB/grip " .. (lb_held and "pressed" or "released"))
        lb_was_held = lb_held
    end

    local toggled = chord_held and not chord_was_held
    if toggled then
        frozen = not frozen
    end
    chord_was_held = chord_held

    vr:set_aim_allowed(not frozen)

    if toggled then
        debug("chord toggled - frozen = " .. tostring(frozen) .. ", is_aim_allowed() now = " .. tostring(vr:is_aim_allowed()))
    end

    if chord_held then
        state.Gamepad.wButtons = buttons & ~XINPUT_GAMEPAD_LEFT_SHOULDER
    end
end)

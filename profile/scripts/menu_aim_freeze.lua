--[[
    RSDWVR - menu_aim_freeze.lua

    Head-aim (VR_AimMethod=1 + VR_AimModifyPlayerControlRotation=true,
    see README "First-person mode") writes the HMD's rotation into the
    PlayerController's ControlRotation every frame with no smoothing,
    which attacks/aim-trace logic reads. Press Left Stick Click (L3) +
    Left Grip together as a toggle (not a hold) to suspend head-aim
    (vr:set_aim_allowed(false)); press the chord again to resume.

    Confirmed working via a temporary debug log (see git history) -
    the chord is detected cleanly and vr:set_aim_allowed toggles
    correctly every press. It does NOT fix the separate menu-follows-
    gaze issue this was originally built for - that turned out to be
    driven by VR_DecoupledPitchUIAdjust in UEVR's own
    OverlayComponent::generate_slate_quad, unrelated to aim/
    ControlRotation entirely (see README and project history for that
    investigation) - so this script's freeze is a real, working tool
    for whatever aim-related use it's needed for, but isn't a menu
    fix on its own.

    Getting to a stable on_xinput_get_state implementation took a lot
    of failed iteration - see git history on this file for the full
    trail (a native crash from doing more than trivial work in that
    callback, a separately-broken get_action_handle API, and a debug
    logging bug that silently prevented the real logic from ever
    running). Left here only as a pointer in case this needs revisiting:
    don't call uevr.params.functions:log_info or
    vr:get_action_handle/is_action_active from on_xinput_get_state, and
    if adding diagnostics here again, use io.open with a *relative*
    path (UEVR's sandbox rejects absolute ones) and always run real
    logic before any debug output in case the debug call throws.
]]

local vr = uevr.params.vr

local frozen = false
local chord_was_held = false

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local buttons = state.Gamepad.wButtons
    local l3_held = (buttons & XINPUT_GAMEPAD_LEFT_THUMB) ~= 0
    local lb_held = (buttons & XINPUT_GAMEPAD_LEFT_SHOULDER) ~= 0
    local chord_held = l3_held and lb_held

    if chord_held and not chord_was_held then
        frozen = not frozen
        vr:set_aim_allowed(not frozen)
    end
    chord_was_held = chord_held
end)

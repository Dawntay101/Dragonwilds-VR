--[[
    RSDWVR - menu_aim_freeze.lua

    Head-aim (VR_AimMethod=1 + VR_AimModifyPlayerControlRotation=true,
    see README "First-person mode") writes the HMD's rotation into the
    PlayerController's ControlRotation every frame with no smoothing.
    That's also the same value UEVR's automatic 3D-projected UI uses to
    orient menus/HUD, so menus re-center on your gaze instantly and
    become unreadable. Fix: press Left Stick Click (L3) + Left Grip
    together as a toggle (not a hold) to suspend head-aim
    (vr:set_aim_allowed(false)); press the chord again to resume.

    CONFIRMED (2026-09-05), across three attempts, that doing *anything*
    inside on_xinput_get_state beyond the bare minimum reliably crashes
    the game (UEVRBackend.dll, STATUS_STACK_BUFFER_OVERRUN) as soon as
    L3 is pressed - including a version with zero string work, only
    booleans/numbers and the vr:set_aim_allowed call. That callback
    fires on whatever thread calls the real XInputGetState, which is
    very likely a different, unsynchronized thread from the one running
    every other Lua callback (on_early_calculate_stereo_view_offset
    etc.) - so this is treated as a poisoned callback for this build and
    avoided entirely now, rather than trying yet another variation
    inside it.

    Switched to UEVR's VR action-handle API instead
    (get_action_handle/is_action_active) - the same API VR.cpp itself
    uses internally to detect grip/thumbstick-click presses (see
    "/actions/default/in/Grip" and "/actions/default/in/JoystickClick"
    in its source) - called from on_early_calculate_stereo_view_offset
    (render thread) instead of on_xinput_get_state. This is the same
    action-handle API controller_bindings.lua tried and abandoned
    earlier for throwing an uncatchable exception - but that attempt
    also called it from inside on_xinput_get_state, which is now known
    to be a bad calling context in general, not necessarily a flaw in
    the action-handle API itself. Untested - if this throws the same
    uncatchable exception even from this callback, the API itself is
    unusable here regardless of calling context, and a fundamentally
    different approach (e.g. giving up on a script-driven chord and
    using a UEVR-native key/button binding config option instead, if
    one exists) would be worth exploring next.
]]

local vr = uevr.params.vr

local grip_action = nil
local joystick_click_action = nil
local left_joystick = nil

local frozen = false
local chord_was_held = false

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    if grip_action == nil then
        grip_action = vr:get_action_handle("/actions/default/in/Grip")
        joystick_click_action = vr:get_action_handle("/actions/default/in/JoystickClick")
        left_joystick = vr:get_left_joystick_source()
    end

    local l3_held = vr:is_action_active(joystick_click_action, left_joystick)
    local lb_held = vr:is_action_active(grip_action, left_joystick)
    local chord_held = l3_held and lb_held

    if chord_held and not chord_was_held then
        frozen = not frozen
        vr:set_aim_allowed(not frozen)
        uevr.params.functions:log_info("[menu_aim_freeze] chord toggled, frozen=" .. tostring(frozen))
    end
    chord_was_held = chord_held
end)

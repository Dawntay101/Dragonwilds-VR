--[[
    RSDWVR - menu_aim_freeze.lua

    DISABLED (2026-09-05) at Kevin's request, to test his hypothesis
    that this script - not the pre-existing UEVRBackend.dll crash
    documented below - is what's causing the game to crash as soon as
    L3 is pressed (L3 doubles as Sprint in this game's native scheme,
    and he could sprint fine before this script existed). The evidence
    gathered so far pointed elsewhere (Windows' own crash record showed
    the identical UEVRBackend.dll fault offset on an injection where
    this script's on_xinput_get_state callback never even ran once),
    but that's exactly the kind of claim that should be settled by
    testing with the variable removed, not by re-arguing the log
    analysis - so head-aim now runs with no manual override at all,
    every frame, no button reads. If it still crashes on L3 with this
    file inert, that's strong confirmation the crash really is
    upstream/pre-existing; if it stops crashing, the earlier analysis
    was wrong somewhere and worth revisiting.

    Original purpose (kept here for when this gets re-enabled): head-aim
    (VR_AimMethod=1 + VR_AimModifyPlayerControlRotation=true, see README
    "First-person mode") writes the HMD's rotation into the
    PlayerController's ControlRotation every frame with no smoothing.
    That's also the same value UEVR's automatic 3D-projected UI uses to
    orient menus/HUD, so menus re-center on your gaze instantly and
    become unreadable. This script's fix was a toggle chord (Left Stick
    Click + Left Grip) calling vr:set_aim_allowed(false) to temporarily
    suspend head-aim so menus hold still - see git history on this file
    for the full working version and the debugging trail (grip->LB
    mapping, mod callback ordering, UEVR source citations) before
    reintroducing it.
]]

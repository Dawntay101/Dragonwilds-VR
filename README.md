api = uevr.api
local vr = uevr.params.vr

-- Weapon offset configuration
--local weapon_location_offset = Vector3f.new(1.9078741073608398, -2.1786863803863525, 11.48326301574707)
local weapon_location_offset = Vector3f.new(0.0, 0.0, 0.0)
local weapon_rotation_offset = Vector3f.new(0.5, 3.3, 0.0)
local weapon_scale_offset = Vector3f.new(0.85, 0.85, 0.85)  -- Maybe too big for some weapons but too small for others? Need to figure out individual offsets

local function hide_Mesh(name)
    if name then
        name:SetRenderInMainPass(false)
        name:SetRenderInDepthPass(false)
        name:SetRenderCustomDepth(false)
    end
end

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)

    local pawn = api:get_local_pawn(0)

    if not pawn or not pawn.Mesh.AttachChildren or not pawn.Children then return end

    for _, component in ipairs(pawn.Mesh.AttachChildren) do

        if string.find(component:get_full_name(), "SkeletalMeshComponent") then
            hide_Mesh(component)
        end
    end

    for _, component in ipairs(pawn.Children) do

        if component and UEVR_UObjectHook.exists(component) and (string.find(component:get_full_name(), "BP_")) and (not string.find(component:get_full_name(), "Oculus_Camera")) and (not string.find(component:get_full_name(), "Arrow")) then
            local state = UEVR_UObjectHook.get_or_add_motion_controller_state(component.RootComponent)
            if state then
        local name = component:get_full_name()
        local isBow = string.find(name, "Shortbow") or string.find(name, "Longbow")
        local isShield = string.find(name, "Shield")
        local isArrow = string.find(name, "Arrow")

        if isBow or isShield or isArrow then
            state:set_hand(0)  -- Left hand-
		else
		    state:set_hand(1)  -- Right hand
        end

                state:set_permanent(false)
              --  state:set_location_offset(weapon_location_offset)
                if  string.find(component:get_full_name(), "Dagger")  then
                    state:set_rotation_offset(Vector3f.new(0.9, 0.3, 0.0)) 
                elseif (string.find(component:get_full_name(), "Shortbow")) or (string.find(component:get_full_name(), "Longbow"))   then
                    state:set_rotation_offset(Vector3f.new(0.5, -3.3, 0.0))
                elseif (string.find(component:get_full_name(), "Shield")) then
                state:set_rotation_offset(Vector3f.new(0.6, 3.0, 0.0))                             
                else
                    state:set_rotation_offset(Vector3f.new(0.9, 3.4, 0.0))
                end
                component.RootComponent.RelativeScale3D = weapon_scale_offset
            end 
        elseif (string.find(component:get_full_name(), "Arrow")) then
            component.RootComponent.RelativeScale3D = Vector3f.new(1.0, 1.0, 1.0)
        end
    end
end)

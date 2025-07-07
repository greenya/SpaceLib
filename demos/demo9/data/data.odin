package demo9_data

Info :: struct {
    welcome         : struct { title: string, content: string },
    notification    : struct { title: string, content: string },
    settings        : map [string] struct { title, desc: string },
}

Player :: struct {
    account_name        : string,
    character_name      : string,
    intel_points_avail  : int,
    skill_points_avail  : int,
}

info: ^Info
player: ^Player

create :: proc () {
    info = new(Info)
    info^ = {
        welcome = {
            title   = "WELCOME TO ARRAKIS",
            content = "A beginning is the time for taking the most delicate care that the balances are correct.",
        },
        notification = {
            title   = "ITEM LOSS ON TRAVEL",
            content = "" +
                "We have received reports that some players have lost items from their inventory while " +
                "traveling to the Deep Desert or Hagga Basin via the World Map after the recent patch." +
                "\n\nWe are investigating the issue and will provide an update as soon as possible." +
                "\n\nThank you.",
        },
    }

    info.settings["sprint_lock"] = {
        title   = "SPRINT LOCK",
        desc    = "Set the Sprint input mode." +
            "\n" +
            "\n<font=text_4m>Toggle:</> Press the Sprint button to toggle between running and walking." +
            "\n<font=text_4m>Hold:</> Keep the Sprint button pressed to run." +
            "\n<font=text_4m>Lock:</> Always Sprint until movement is interrupted or stopped.",
    }

    info.settings["equip_lock"] = {
        title   = "EQUIP LOCK",
        desc    = "Toggle the equip lock off or on." +
            "\n" +
            "\n<font=text_4m>ON:</> Holster the equipped weapon by pressing the dedicated holstering input." +
            "\n<font=text_4m>OFF:</> Holster the equipped weapon by pressing the same shortcut and/or radial.",
    }

    info.settings["suspensor_lock"] = {
        title   = "SUSPENSOR LOCK",
        desc    = "Toggle the suspensor lock off or on." +
            "\n" +
            "\n<font=text_4m>ON:</> Press and press again to use the suspensors, without input hold." +
            "\n<font=text_4m>OFF:</> Press and hold to use the suspensors.",
    }

    info.settings["invert_mouse_y_axis"] = {
        title   = "INVERT MOUSE Y-AXIS",
        desc    = "Invert the camera controls along the vertical axis.",
    }

    info.settings["mouse_camera_sensitivity"] = {
        title   = "MOUSE CAMERA SENSITIVITY",
        desc    = "Adjust the sensitivity of how quickly the Character Camera moves.",
    }

    info.settings["mouse_aiming_sensitivity"] = {
        title   = "MOUSE AIMING SENSITIVITY",
        desc    = "Adjust the sensitivity of how quickly the Character Camera moves while aiming down sight.",
    }

    info.settings["camera_shakes"] = {
        title   = "CAMERA SHAKES",
        desc    = "Turns the brief camera movements on or off in fights, when receiving fall damage, and other impactful effects.",
    }

    info.settings["show_helmet"] = {
        title   = "SHOW HELMET",
        desc    = "Display the equipped helmet on your character.",
    }

    // BUILDING

    info.settings["building:placeable_rotation_building_mode"] = {
        title   = "PLACEABLE ROTATION BUILDING MODE",
        desc    = "Set the placeable rotation method when using building mode.",
    }

    // VEHICLES

    info.settings["vehicles:disable_camera_auto_center"] = {
        title   = "DISABLE CAMERA AUTO-CENTER",
        desc    = "Enable or disable the camera centering automatically after moving with vehicles.",
    }

    // AIR VEHICLES

    info.settings["air_vehicles:invert_mouse_y_axis"] = {
        title   = "INVERT MOUSE Y-AXIS",
        desc    = "Invert the air vehicle controls along the vertical axis.",
    }

    info.settings["air_vehicles:planar_lock"] = {
        title   = "PLANAR LOCK",
        desc    = "Set the planar lock on or off." +
            "\n" +
            "\n<font=text_4m>ON:</> The ornithopter will change altitude only with the ascend and descend inputs." +
            "\n<font=text_4m>OFF:</> The ornithopter will change altitude also based on the direction faced when pitching.",
    }

    // RADIAL WHEEL

    info.settings["radial_wheel:input_lock_mode_mouse"] = {
        title   = "INPUT LOCK MODE MOUSE",
        desc    = "Controls the behaviour of the radial wheel slot highlighting based on the mouse cursor position." +
            "\n" +
            "\n<font=text_4m>Flick & Remember:</>" +
            "\nNo slot is highlighted by default. Moving the mouse cursor to the centre of the wheel will not unhighlight the currently highlighted slot." +
            "\n" +
            "\n<font=text_4m>Flick & Forget:</>" +
            "\nNo slot is highlighted by default. Moving the mouse cursor to the centre of the wheel will unhighlight the currently highlighted slot.",
    }

    info.settings["radial_wheel:close_behaviour"] = {
        title   = "CLOSE BEHAVIOUR",
        desc    = "Controls the behaviour of the controller left thumbstick input to the character movement after the radial wheel has been closed." +
            "\n" +
            "\n<font=text_4m>Require Axis Input Reset:</>" +
            "\nThe character will not move in the direction of the left thumbstick until either it has been returned to the centre or the delay time has been reached after closing the radial wheel." +
            "\nAffected by the controller axis reset deadzone and controller axis reset delay (s) settings." +
            "\n" +
            "\n<font=text_4m>Maintain Axis Input:</>" +
            "\nThe character will move in the direction of the left thumbstick after closing the radial wheel.",
    }

    player = new(Player)
    player^ = {
        account_name        = "spacemad#12345",
        character_name      = "Skywalker",
        intel_points_avail  = 123,
        skill_points_avail  = 1,
    }
}

destroy :: proc () {
    delete(info.settings)
    free(info)
    free(player)
}

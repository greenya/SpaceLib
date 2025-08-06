package spacelib_raylib_env

import rl "vendor:raylib"
import "../../core"

@private Vec2 :: core.Vec2
@private Rect :: core.Rect

window_size :: proc () -> Vec2 { return { f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) } }

scissor_set     :: proc (r: Rect) { rl.BeginScissorMode(i32(r.x), i32(r.y), i32(r.w), i32(r.h)) }
scissor_clear   :: proc () { rl.EndScissorMode() }

mouse_pos           :: rl.GetMousePosition
mouse_button_down   :: rl.IsMouseButtonDown
mouse_wheel_dy      :: rl.GetMouseWheelMove
mouse_wheel_dxy     :: rl.GetMouseWheelMoveV

key_down :: rl.IsKeyDown

package hi

Text_Style :: struct {
    ctx: ^Context,

    font                : string,
    font_scale          : f32,
    font_baseline_ratio : f32, // Baseline position from `0.0` (top) to `1.0` (bottom)
    color               : Color,
    align               : Text_Alignment,
    wrapping            : bool,

    user_ptr: rawptr,
    user_idx: int,
}

@rodata
Text_Style_Default := Text_Style {
    font_scale          = 1.0,
    font_baseline_ratio = 0.8,
    color               = {255,255,255,255},
    wrapping            = true,
}

Text_Alignment :: enum u8 { left, right, center }

@require_results
_text_style_init :: proc (v: ^View) -> Text_Style {
    style := Text_Style_Default
    style.ctx = v.ctx
    if v.ctx.on_text_style_init != nil do v.ctx.on_text_style_init(v, &style)
    return style
}

@require_results
text_style_font_height :: proc (style: Text_Style) -> f32 {
    assert(style.ctx != nil)
    return style.font_scale * style.ctx.ref_font_height
}

@require_results
text_style_font_height_screen :: proc (style: Text_Style) -> f32 {
    assert(style.ctx != nil)
    return style.font_scale * style.ctx.ref_font_height * style.ctx.screen_pixel_scale
}

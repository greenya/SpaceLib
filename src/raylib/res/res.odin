package spacelib_raylib_res

// TODO: add textures and sprites support
// TODO: add audios support

Res :: struct {
    files: map [string] File,
    fonts: map [string] ^Font,
    textures: map [string] ^Texture,
    sprites: map [string] ^Sprite,
    // audios: map [string] Music/Sound/Wave,
    // colors: map [string] ^Color,
}

create_resources :: proc () -> ^Res {
    res := new(Res)
    return res
}

destroy_resources :: proc (res: ^Res) {
    delete(res.files)
    destroy_fonts(res)
    destroy_sprites_and_textures(res)
    free(res)
}

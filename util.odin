package main

import "core:log"
import "core:fmt"
import "core:runtime"
import "vendor:sdl2"
import "vendor:sdl2/image"


// it appears implementation of default logger proc at the moment 
// of writing this code is literally this: '// Nothing' :)
logger_proc :: proc(data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location)
{
   if level == .Fatal do runtime.panic(text, location);
   fmt.println(text);
}


LoadPNGSurface :: proc(filename: cstring) -> ^sdl2.Surface
{
   rwops := sdl2.RWFromFile(filename, "rb");
   defer sdl2.FreeRW(rwops);

   surface := image.LoadPNG_RW(rwops);
   if surface == nil do log.fatal("sdl2 failed to load '", filename, "' to a surface. ", sdl2.GetError());

   return surface;
}


LoadPNGTexture :: proc(filename: cstring, render: ^sdl2.Renderer) -> ^sdl2.Texture
{
   surface := LoadPNGSurface(filename);
   defer sdl2.FreeSurface(surface);

   texture := sdl2.CreateTextureFromSurface(render, surface);
   if texture == nil do log.fatal("sdl2 failed to load '", filename, "' to a texture. ", sdl2.GetError());

   return texture;
}

package main 

import "core:log"
import "vendor:sdl2"


Animation :: struct {
   rect:   sdl2.Rect
   sprite: ^Sprite
};


CreateAnimation :: proc(texture: ^sdl2.Texture, rect: sdl2.Rect, sprite_w:i32 = PAWN_WIDTH) -> ^Animation
{
   self := new(Animation);
   if self == nil do log.fatal("memory allocation failure");

   self.sprite = CreateSprite(texture, sprite_w, false);
   self.rect = rect;

   return self;
}


RenderAnimation :: proc(self: ^Animation, render: ^sdl2.Renderer)
{
   RenderSprite(self.sprite, render, &self.rect);
}


DestroyAnimation :: proc(self: ^Animation)
{
   DestroySprite(self.sprite);
   free(self);
}

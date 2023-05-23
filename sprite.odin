package main 

import "core:log"
import "vendor:sdl2"
import "vendor:sdl2/image"


Sprite :: struct {
   loop:    bool,
   texture: ^sdl2.Texture,
   rect:    sdl2.Rect
   frames:  []i32,
   frame:   int,
};


CreateSprite :: proc(texture: ^sdl2.Texture, frame_width: i32, loop: bool = true) -> ^Sprite
{
   w, h : i32 = 0, 0;
   frame_width := frame_width;

   self, err := new(Sprite);
   if self == nil do log.fatal("memory allocation failure");

   sdl2.QueryTexture(texture, nil, nil, &w, &h);

   //sanitize input
   if frame_width <= 0 || frame_width > w { frame_width = w; }
   n_frames := w / frame_width;

   self.frames = make([]i32, n_frames);
   if self.frames == nil do log.fatal("memory allocation failure");

   //calc frames offsets
   for i in 0 ..< n_frames do self.frames[i] = i * frame_width;

   self.rect = { 0, 0, frame_width, h };
   self.texture = texture;
   self.loop = loop;

   return self;
}


DestroySprite :: proc(self: ^Sprite) 
{
   delete(self.frames);
   free(self);  
}


nextFrame :: proc(self: ^Sprite)
{
   //if last frame reached
   if self.frame == len(self.frames) - 1 {
      if self.loop { self.rect.x, self.frame = 0, 0; }
      return;
   }
   
   self.frame += 1;
   self.rect.x = self.frames[self.frame];
}


RenderSprite :: proc(self: ^Sprite, render: ^sdl2.Renderer, dest_rect: ^sdl2.Rect)
{
   sdl2.RenderCopy(render, self.texture, &self.rect, dest_rect);
   nextFrame(self);
}

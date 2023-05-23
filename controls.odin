package main

import "core:math"
import "core:slice"
import "vendor:sdl2"


BulletStatus :: enum { Inactive, Active, Empty };
Tool :: enum { Move, Sprint, Shoot, Punch, BulletHail, Wait };


Drum :: struct {
   bullets:   [6]BulletStatus,
   cords:     [6]sdl2.Rect,
   rect:      sdl2.Rect,
};


Controls :: struct {
   sprinting:    bool,
   rect:         sdl2.Rect,
   toolRect:     sdl2.Rect,
   drum:         Drum,
   cooldowns:    [6]int,
   selectedTool: Tool,
};


SwitchToolDown :: proc(self: ^Controls)
{
   if self.sprinting == true do return;
   self.selectedTool = Tool((int(self.selectedTool) + 1) % 6);
   if self.cooldowns[self.selectedTool] > 0 do SwitchToolUp(self);
}


SwitchToolUp :: proc(self: ^Controls)
{
   if self.sprinting == true do return;
   tool := (int(self.selectedTool) - 1);
   self.selectedTool = tool >= 0 ? Tool(tool) : Tool(5);
   if self.cooldowns[self.selectedTool] > 0 do SwitchToolDown(self);
}


RollDrumLeft :: proc(self: ^Controls)
{
   slice.rotate_left(self.drum.bullets[:], 1);
}


RollDrumRight :: proc(self: ^Controls)
{
   slice.rotate_right(self.drum.bullets[:], 1);
}


Cooldown :: proc(self: ^Controls)
{
   for i in 0 ..< len(self.cooldowns) {
      if self.cooldowns[i] > 0 do self.cooldowns[i]-=1;
   }
}


InitDrum :: proc(self: ^Drum, rect: sdl2.Rect)
{
   self.rect = rect;
   self.rect.w = rect.h;
   self.rect.x = rect.w/2 - rect.h/2;

   pad : i32 = 4; 
   bw : i32 = BULLET_WIDTH;
   a : i32 = self.rect.w/5 - 2;
   b := i32(math.sqrt(f32(a*a*4 - a*a)));  

   y0 := self.rect.y + pad + 4;
   x0 := self.rect.x + pad;

   //place bullets as vertexes of a hexagon inside a drum
   self.cords[0] = { x0, y0+b, bw, bw };
   self.cords[1] = { x0 + a, y0, bw, bw };
   self.cords[2] = { x0 + a*3, y0, bw, bw };
   self.cords[3] = { x0 + a*4, y0+b, bw, bw };
   self.cords[4] = { x0 + a*3, y0+b*2, bw, bw };
   self.cords[5] = { x0 + a, y0+b*2, bw, bw };
}


InitControls :: proc(self: ^Controls, rect: sdl2.Rect)
{
   InitDrum(&self.drum, rect);
   self.toolRect = { rect.w/2 - 15, rect.y + rect.h/2 -15 , 30, 30 };
   self.rect = rect;
}


RenderControls :: proc(self: ^Controls, render: ^sdl2.Renderer)
{
   tool : ^sdl2.Texture;
   switch self.selectedTool {
      case .Move: tool = textures.move;
      case .Sprint: tool = textures.sprint;
      case .Punch: tool = textures.punch;
      case .Shoot: tool = textures.shoot;
      case .BulletHail: tool = textures.bullethail;
      case .Wait: tool = textures.wait;
   }
   
   sdl2.RenderCopy(render, tool, nil, &self.toolRect);

   bullet : ^sdl2.Texture;
   sdl2.RenderCopy(render, textures.drum, nil, &self.drum.rect);

   for i in 0 ..< 6 {

      if self.drum.bullets[i] == .Empty do bullet = textures.empty_bullet;
      else if self.drum.bullets[i] == .Inactive do bullet = textures.inactive_bullet;
      else do bullet = textures.active_bullet;

      sdl2.RenderCopy(render, bullet, nil, &self.drum.cords[i]);
   }
}

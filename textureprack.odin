package main

import "core:os"
import "core:unicode/utf8"
import "vendor:sdl2"


TexturePack :: struct {
   //effect sprites
   explossion,
   death,
   bang,
   w,
   l,

   //active pawn sprites
   player,
   ranger,
   bombot,
   axe,
   cow,

   //static pawn sprites
   barrel,
   plant,

   bomb1,
   bomb2,
   bomb3,

   //controls
   drum,
   empty_bullet,
   active_bullet,
   inactive_bullet,

   //actions
   move,
   sprint,
   punch,
   shoot,
   bullethail,
   wait,

   //map textures
   // // cell
   selection,
   cell: ^sdl2.Texture,
};


InitTexturePack :: proc(self: ^TexturePack, render: ^sdl2.Renderer, path: string)
{
   os.set_current_directory(path);
   self.explossion = LoadPNGTexture("explossion.png", render); 
   self.death = LoadPNGTexture("death.png", render); 
   self.bang = LoadPNGTexture("bang.png", render);
   self.w = LoadPNGTexture("w.png", render);
   self.l = LoadPNGTexture("l.png", render);

   self.player = LoadPNGTexture("player.png", render); 
   self.ranger = LoadPNGTexture("ranger.png", render); 
   self.bombot = LoadPNGTexture("bombot.png", render); 
   self.cow = LoadPNGTexture("cow.png", render); 
   self.axe = LoadPNGTexture("axe.png", render); 

   self.barrel = LoadPNGTexture("barrel.png", render); 
   self.plant = LoadPNGTexture("plant.png", render); 

   self.bomb1 = LoadPNGTexture("bomb1.png", render); 
   self.bomb2 = LoadPNGTexture("bomb2.png", render); 
   self.bomb3 = LoadPNGTexture("bomb3.png", render); 

   self.bomb3 = LoadPNGTexture("bomb3.png", render); 

   self.move = LoadPNGTexture("move.png", render);
   self.sprint = LoadPNGTexture("sprint.png", render); 
   self.punch = LoadPNGTexture("punch.png", render); 
   self.shoot = LoadPNGTexture("shoot.png", render); 
   self.bullethail = LoadPNGTexture("bullethail.png", render); 
   self.wait = LoadPNGTexture("wait.png", render); 

   self.drum = LoadPNGTexture("drum.png", render); 
   self.empty_bullet = LoadPNGTexture("empty_bullet.png", render); 
   self.active_bullet = LoadPNGTexture("active_bullet.png", render); 
   self.inactive_bullet = LoadPNGTexture("inactive_bullet.png", render); 

   self.selection = LoadPNGTexture("selection.png", render);
   self.cell = LoadPNGTexture("cell.png", render); 
}

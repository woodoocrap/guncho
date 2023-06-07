package main

import "core:log"
import "core:time"
import "core:sync"
import "core:thread"
import "vendor:sdl2"


//configs
GRID_PADDING :: 30;
BULLET_WIDTH :: 15;
BULLET_PADDING :: 5;
GRID_OFFSET :: 15;
PAWN_OFFSET :: 18;
PAWN_WIDTH :: 64;


Game :: struct {
   tick:         time.Duration,
   window:       ^sdl2.Window,
   render:       ^sdl2.Renderer,

   level:        ^Level,
   controls:      Controls,
   
   render_loop:  ^thread.Thread,
   mutex:        sync.Mutex,
   run:          bool
};


textures: TexturePack


CreateGame :: proc(width, height: i32, tick: time.Duration) -> ^Game
{
   self := new(Game);
   if self == nil do log.fatal("memory allocation failure");

   err := sdl2.Init({.VIDEO});
   if err != 0 do log.fatal("sdl init failed. ", sdl2.GetError());
      
   self.window = sdl2.CreateWindow(":):", 0, 0, width, height, { .OPENGL, .RESIZABLE });
   if self.window == nil do log.fatal("sdl2 failed to create a window. ", sdl2.GetError());

   self.render = sdl2.CreateRenderer(self.window, -1, {.ACCELERATED});
   if self.render == nil do log.fatal("sdl2 failed to create a render. ", sdl2.GetError());
   sdl2.SetRenderDrawColor(self.render, 0xe0, 0xe0, 0xe0, 0xff);
   sdl2.RenderSetLogicalSize(self.render, width, height);
   
   InitTexturePack(&textures, self.render, "./pics");

   level_rect : sdl2.Rect = { 0, 0, width, height - height/5 };
   controls_rect : sdl2.Rect = { 0, height - height/5, width, height/5 };

   InitControls(&self.controls, controls_rect);
   self.level = CreateLevel(self.render, level_rect, 6, 7);

   self.tick = tick;

   return self;
}


DestroyGame :: proc(self: ^Game)
{
   self.run = false;
   thread.join(self.render_loop);

   sdl2.DestroyRenderer(self.render);
   sdl2.DestroyWindow(self.window);
   DestroyLevel(self.level);
   sdl2.Quit();
}


StartGame :: proc(self: ^Game)
{
   self.run = true;
   self.render_loop = thread.create_and_start_with_data(self, renderLoop);

   //event loop 
   event: sdl2.Event;
   for sdl2.WaitEvent(&event) {
      #partial switch event.type {

         case .KEYDOWN:
            #partial switch event.key.keysym.sym {

               case .a: fallthrough; case .LEFT:
                  SelectLeft(self.level, &self.controls);

               case .d: fallthrough; case .RIGHT:
                  SelectRight(self.level, &self.controls);

               case .s: fallthrough; case .DOWN: 
                  SwitchToolDown(&self.controls);
                  Reselect(self.level, &self.controls);

               case .w: fallthrough; case .UP:
                  SwitchToolUp(&self.controls);
                  Reselect(self.level, &self.controls);

               case .SPACE: fallthrough; case .RETURN: 
                  ProcessAction(self);
            }

         case .QUIT:
            self.run = false;
            return;
      }
   }
}


renderLoop :: proc(data: rawptr)
{
   self := cast(^Game) data;
   //each thread has its own context
   context.logger.procedure = logger_proc;

   for self.run {
      sync.mutex_lock(&self.mutex);

      sdl2.RenderClear(self.render);
      RenderLevel(self.level, self.render);


      RenderControls(&self.controls, self.render);
      sdl2.RenderPresent(self.render);
      sync.mutex_unlock(&self.mutex);
      time.sleep(self.tick);
   }
}


ProcessAction :: proc(self: ^Game)
{
   switch self.controls.selected_tool {
      
      case .Move: MovePlayer(self.level);

      case .Sprint: 
         
         if self.controls.sprinting { 
            self.controls.cooldowns[Tool.Sprint] = 2;
            self.controls.selected_tool = .Move;
         }

         self.controls.sprinting = !self.controls.sprinting;
         MovePlayer(self.level);

      case .Shoot:
         
         dir := self.level.direction;
         // reload
         if self.controls.drum.bullets[dir] == .Empty {
            self.controls.drum.bullets[dir] = .Inactive;
            return;
         }

         if !hasTarget(self, self.level.selected_cell) do return;

         shotsFired(self, self.level.selected_cell);
         Reselect(self.level, &self.controls);
         self.controls.drum.bullets[dir] = .Empty;
         doBang(self, self.level.player.cell);
   
         time.sleep(self.tick * 3);
         if dir == .Left || dir == .UpperLeft || dir == .UpperRight {
            RollDrumLeft(&self.controls);
         } else {
            RollDrumRight(&self.controls);
         }

      case .Punch: 
         if !hasTarget(self, self.level.selected_cell) do return;
         self.level.selected_cell.pawn.stuned = true;
         self.controls.cooldowns[Tool.Punch] = 2;
         pushPawn(self);

      case .BulletHail:
         for dir in Dir {
            if self.controls.drum.bullets[dir] == .Empty do continue;
            self.controls.drum.bullets[dir] = .Empty;
            cell := FindTarget(self.level.player.cell, dir);
            if cell != nil { 
               doBang(self, self.level.player.cell);
               shotsFired(self, cell);
            }
            time.sleep(self.tick * 3);
         }
         
         for dir in Dir { 
            self.controls.drum.bullets[dir] = .Inactive;
            time.sleep(self.tick);
         }

         self.controls.cooldowns[Tool.BulletHail] = 4;

      case .Wait:
   }
}


hasTarget :: proc(self: ^Game, cell: ^Cell) -> bool 
{
   if cell == nil do return false
   if cell.pawn == nil do return false;

   return true;
}


//presumes target exists
shotsFired :: proc(self: ^Game, cell: ^Cell)
{  
   pawn := cell.pawn;

   switch pawn.type {
      case .Ranger: fallthrough; case .Cow: fallthrough
      case .Axe: fallthrough; case .Bombot:
         DestroyPawn(pawn);
         AddAnimation(self, textures.death, cell.rect);
      
      case .Barrel: 
         DestroyPawn(pawn);
         AddAnimation(self, textures.explossion, cell.rect);
         for dir in Dir { 
            if hasTarget(self, cell.nodes[dir]) {
               shotsFired(self, cell.nodes[dir]);
            }
         }

      case .Player: 
         // play death effect
         // endgame

      case .Plant: return;
      case .Bomb: return;
   }
}


pushPawn :: proc(self: ^Game)
{
   dir := self.level.direction;
   cell := self.level.selected_cell;

   if cell.nodes[dir] == nil do return;
   if cell.nodes[dir].pawn != nil do return;;

   MovePawn(self.level.selected_cell.pawn, cell.nodes[dir]);
}


AddAnimation :: proc(self: ^Game, texture: ^sdl2.Texture, rect: sdl2.Rect)
{
   sync.mutex_lock(&self.mutex);
   append(&self.level.grid.animations, CreateAnimation(texture, rect));
   sync.mutex_unlock(&self.mutex);
}


doBang :: proc(self: ^Game, cell: ^Cell)
{
   rect := cell.rect;
   rect.x -= PAWN_WIDTH / 2;
   rect.y -= PAWN_OFFSET;

   AddAnimation(self, textures.bang, rect);
}

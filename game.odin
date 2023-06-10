package main

import "core:log"
import "core:time"
import "core:math"
import "core:sync"
import "core:thread"
import "vendor:sdl2"


//configs
GAME_TICK :: 120000000;
GRID_PADDING :: 30;
BULLET_WIDTH :: 15;
BULLET_PADDING :: 5;
GRID_OFFSET :: 15;
PAWN_OFFSET :: 18;
PAWN_WIDTH :: 64;

// TODO: move grid representation to matrix

Game :: struct {
   tick:         time.Duration,
   window:       ^sdl2.Window,
   render:       ^sdl2.Renderer,

   level:        ^Level,
   controls:      Controls,
   
   render_loop:  ^thread.Thread,
   run:          bool
};


textures: TexturePack
mutex: sync.Mutex


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
            ProcessInput(self, event.key.keysym.sym);   

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
      sync.mutex_lock(&mutex);

      sdl2.RenderClear(self.render);

      RenderLevel(self.level, self.render);
      RenderControls(&self.controls, self.render);

      sdl2.RenderPresent(self.render);

      sync.mutex_unlock(&mutex);
      time.sleep(self.tick);
   }
}


ProcessInput :: proc(self: ^Game, key: sdl2.Keycode)
{
   #partial switch key {

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

         if !ProcessAction(self) do return;
         if self.level.over { EndGame(self); return; }
         EnemyTurn(self.level);
         if self.level.over { EndGame(self); return; }

         Cooldown(&self.controls);
         Reselect(self.level, &self.controls);
   }
}


AnimateCharge :: proc(pawn: ^Pawn, cell: ^Cell)
{
   a := math.abs(pawn.cell.x - cell.x);
   b := math.abs(pawn.cell.y - cell.y);
   
   dist := (a > b ? a : b) * 2;

   step_x := (cell.rect.x - pawn.cell.rect.x) / dist;
   step_y := (cell.rect.y - pawn.cell.rect.y) / dist;

   for i in 0 ..< dist {
      pawn.rect.x += step_x;
      pawn.rect.y += step_y;
      time.sleep(GAME_TICK);
   }
}


EndGame :: proc(self: ^Game)
{  
   time.sleep(self.tick * 4);
   sync.mutex_lock(&mutex);
   
   ClearLevel(self.level);
   ResetControls(&self.controls);
   InitLevel(self.level);

   sync.mutex_unlock(&mutex);
}

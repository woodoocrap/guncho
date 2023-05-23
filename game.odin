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
               case .LEFT: SelectLeft(self.level);
               case .RIGHT: SelectRight(self.level);
               case .DOWN: SwitchToolDown(&self.controls);
               case .UP: SwitchToolUp(&self.controls);
            }
         case .WINDOWEVENT: 
            //window_surface = sdl2.GetWindowSurface(window);
            //if event.window.event == .RESIZED do sdl2.GetWindowSize(window, &window_rect.w, &window_rect.h);

         case .QUIT: return;
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

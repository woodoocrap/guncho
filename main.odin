package main

import "core:log"
import "core:fmt"
import "core:time"
import "core:thread"
import "core:runtime"

import "vendor:sdl2"
import "vendor:sdl2/image"


main :: proc() {
   context.logger.procedure = logger_proc;

   width, height: i32 = 400, 350;
   
   game := CreateGame(width, height, GAME_TICK);
   defer DestroyGame(game);

   StartGame(game);
}

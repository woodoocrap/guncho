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

   game := CreateGame(GAME_WIDTH, GAME_HEIGHT, GAME_TICK);
   defer DestroyGame(game);

   StartGame(game);
}

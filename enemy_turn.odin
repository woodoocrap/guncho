package main

import "core:log"
import "core:time"
import "vendor:sdl2"


triggerBomb :: proc(self: ^Level, bomb: ^Pawn)
{
   cell := bomb.cell;
   DestroyPawn(bomb);

   AddAnimation(self, textures.explossion, cell.rect);
   blastRadius(self, cell);
}


EnemyTurn :: proc(self: ^Level)
{
   if self.enemies == 0 {
      // well thats a W
      return;
   }

   for row in self.grid.cells {
      for cell in row {
         if cell.pawn == nil do continue;
         #partial switch cell.pawn.type {
            case .Bomb:
               if cell.pawn.timer == 0 do triggerBomb(self, cell.pawn);
               else do cell.pawn.timer -= 1;
            case .Ranger:
         }
      }
   }
}

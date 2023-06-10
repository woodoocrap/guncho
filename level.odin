package main

import "core:log"
import "core:sync"
import "vendor:sdl2"
import "core:math/rand"

Level :: struct {
   selected_cell: ^Cell,
   direction:     Dir,
   // is there something like std::set?
   pawns:         map[^Pawn]bool,
   over:          bool,
   player:        ^Pawn,
   grid:          ^Grid,
   enemies:       int,
   rows:          i32,
   cols:          i32,
};


CreateLevel :: proc(render: ^sdl2.Renderer, rect: sdl2.Rect, rows, cols: i32) -> ^Level
{
   self := new(Level);
   if self == nil do log.fatal("memory allocation failure");

   self.grid = CreateGrid(render, rect, rows, cols); 
   
   self.rows = rows;
   self.cols = cols;
   InitLevel(self);

   return self;
}


InitLevel :: proc(self: ^Level)
{
   self.player = CreatePawn(&self.grid.cells[self.rows-1][self.cols/2], .Player);

   enemie_count := rand.int_max(4) + 4;
   static_count := rand.int_max(4) + 4;

   for i in 0 ..< enemie_count {
      for true {
         x, y : i32 = genRandomCords(self.cols, self.rows-1);
         if self.grid.cells[y][x].pawn == nil {
            pawn_type := PawnType(rand.int_max(4));
            self.pawns[CreatePawn(&self.grid.cells[y][x], pawn_type)] = true;
            break;
         } 
      }
   }

   for i in 0 ..< static_count {
      for true {
         x, y : i32 = genRandomCords(self.cols, self.rows-1);
         if self.grid.cells[y][x].pawn == nil {
            pawn_type := PawnType(rand.int_max(2) + 5);
            self.pawns[CreatePawn(&self.grid.cells[y][x], pawn_type)] = true;
            break;
         } 
      }
   }

   self.enemies = enemie_count;
}


ClearLevel :: proc(self: ^Level)
{
   self.over = false;
   deselectCell(self);
   for pawn in self.pawns {
      delete_key(&self.pawns, pawn);
      DestroyPawn(pawn);
   }

}


RenderLevel :: proc(self: ^Level, render: ^sdl2.Renderer)
{
   RenderGrid(self.grid, render);
}


genRandomCords :: proc(w, h: i32) -> (i32, i32)
{
   x := rand.int31_max(w);
   y := rand.int31_max(h);
   
   return x, y;
}


DestroyLevel :: proc(self: ^Level)
{
   DestroyGrid(self.grid);
   delete(self.pawns);
   free(self);
}


SelectCell :: proc(self: ^Level, cell: ^Cell)
{
   if self.selected_cell != nil do self.selected_cell.selected = false;
   if cell != nil do cell.selected = true;
   self.selected_cell = cell;
}



trySelectDir :: proc(self: ^Level, ctrl: ^Controls) -> bool
{
   if node(self, self.player.cell, self.direction) == nil do return false;
      
   if ctrl.selected_tool == .Shoot {
      target_cell := FindTarget(self, self.player.cell, self.direction);
      if target_cell != nil {
         SelectCell(self, target_cell);
         return true;
      }
   }

   SelectCell(self, node(self, self.player.cell, self.direction));   
   return true;
}


Reselect :: proc(self: ^Level, ctrl: ^Controls) { trySelectDir(self, ctrl); }


SelectRight :: proc(self: ^Level, ctrl: ^Controls)
{
   self.direction = IncDir(self.direction)
   if trySelectDir(self, ctrl) == true do return;
   
   SelectRight(self, ctrl);
}


SelectLeft :: proc(self: ^Level, ctrl: ^Controls)
{
   self.direction = DecDir(self.direction);
   if trySelectDir(self, ctrl) == true do return;

   SelectLeft(self, ctrl);
}


MovePlayer :: proc(self: ^Level) -> bool
{
   if self.selected_cell == nil do return false;
   if self.selected_cell.pawn != nil do return false;
   
   MovePawn(self.player, self.selected_cell);
   deselectCell(self);

   return true;
}


deselectCell :: proc(self: ^Level)
{
   if self.selected_cell == nil do return;
   self.selected_cell.selected = false;
   self.selected_cell = nil;
}


AddAnimation :: proc(self: ^Level, texture: ^sdl2.Texture, rect: sdl2.Rect, sprite_w: i32 = PAWN_WIDTH)
{
   sync.mutex_lock(&mutex);
   append(&self.grid.animations, CreateAnimation(texture, rect, sprite_w));
   sync.mutex_unlock(&mutex);
}


doBang :: proc(self: ^Level, cell: ^Cell)
{
   rect := cell.rect;
   rect.x -= PAWN_WIDTH / 2;
   rect.y -= PAWN_OFFSET;

   AddAnimation(self, textures.bang, rect);
}

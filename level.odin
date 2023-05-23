package main

import "core:log"
import "vendor:sdl2"
import "core:math/rand"

Level :: struct {
   selected_cell: ^Cell,
   direction:     Dir,
   enemies:       [dynamic]^Pawn,
   player:        ^Pawn,
   grid:          ^Grid,
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
   enemie_count := rand.int_max(4) + 4;
   static_count := rand.int_max(4) + 4;

   self.player = CreatePawn(&self.grid.cells[self.rows-1][self.cols/2], .Player);
   
   self.enemies = make([dynamic]^Pawn, enemie_count);
   if self.enemies == nil do log.fatal("memory allocation failure");

   for i in 0 ..< enemie_count {
      for true {
         x, y : i32 = genRandomCords(self.cols, self.rows-1);
         if self.grid.cells[y][x].pawn == nil {
            pawn_type := PawnType(rand.int_max(4));
            append(&self.enemies, CreatePawn(&self.grid.cells[y][x], pawn_type));
            break;
         } 
      }
   }

   for i in 0 ..< static_count {
      for true {
         x, y : i32 = genRandomCords(self.cols, self.rows-1);
         if self.grid.cells[y][x].pawn == nil {
            pawn_type := PawnType(rand.int_max(2) + 5);
            CreatePawn(&self.grid.cells[y][x], pawn_type);
            break;
         } 
      }
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
   delete(self.enemies);
   
   free(self);
}


SelectCell :: proc(self: ^Level, cell: ^Cell)
{
   if self.selected_cell != nil do self.selected_cell.selected = false;
   if cell != nil do cell.selected = true;
   self.selected_cell = cell;
}


SelectRight :: proc(self: ^Level)
{
   self.direction = Dir((int(self.direction) + 1) % 6);
   if self.player.cell.nodes[self.direction] != nil {
      SelectCell(self, self.player.cell.nodes[self.direction]);   
      return;
   }

   SelectRight(self);
}


SelectLeft :: proc(self: ^Level)
{
   dir := (int(self.direction) - 1);
   self.direction = dir >= 0 ? Dir(dir) : Dir(5);

   if self.player.cell.nodes[self.direction] != nil {
      SelectCell(self, self.player.cell.nodes[self.direction]);   
      return;
   }

   SelectLeft(self);
}

package main

import "core:log"
import "core:sync"
import "vendor:sdl2"
import "core:math/rand"

Level :: struct {
   selected_cell: ^Cell,
   direction:     Dir,
   enemies:       int,
   player:        ^Pawn,
   grid:          ^Grid,
   rows:          i32,
   cols:          i32,
   player_x:      i32,
   player_y:      i32,
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
   self.player_x = self.rows - 1;
   self.player_y = self.cols / 2;
   self.player = CreatePawn(&self.grid.cells[self.player_y][self.player_x], .Player);

   enemie_count := rand.int_max(4) + 4;
   static_count := rand.int_max(4) + 4;

   for i in 0 ..< enemie_count {
      for true {
         x, y : i32 = genRandomCords(self.cols, self.rows-1);
         if self.grid.cells[y][x].pawn == nil {
            pawn_type := PawnType(rand.int_max(4));
            CreatePawn(&self.grid.cells[y][x], pawn_type);
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

   self.enemies = enemie_count;
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
   if self.player.cell.nodes[self.direction] == nil do return false;
      
   if ctrl.selected_tool == .Shoot {
      target_cell := FindTarget(self.player.cell, self.direction);
      if target_cell != nil {
         SelectCell(self, target_cell);
         return true;
      }
   }

   SelectCell(self, self.player.cell.nodes[self.direction]);   
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
   UpdateCords(self);

   return true;
}


UpdateCords :: proc(self: ^Level)
{
   switch self.direction {
      case .LowerLeft: self.player_y += 1; self.player_x -= 1;
      case .LowerRight: self.player_y += 1; self.player_x += 1;
      case .UpperLeft: self.player_y -= 1; self.player_x -= 1;
      case .UpperRight: self.player_y -= 1; self.player_x += 1;
      case .Right: self.player_x += 1;
      case .Left: self.player_x -= 1;
   }
}


deselectCell :: proc(self: ^Level)
{
   self.selected_cell.selected = false;
   self.selected_cell = nil;
}


AddAnimation :: proc(self: ^Level, texture: ^sdl2.Texture, rect: sdl2.Rect)
{
   sync.mutex_lock(&mutex);
   append(&self.grid.animations, CreateAnimation(texture, rect));
   sync.mutex_unlock(&mutex);
}


doBang :: proc(self: ^Level, cell: ^Cell)
{
   rect := cell.rect;
   rect.x -= PAWN_WIDTH / 2;
   rect.y -= PAWN_OFFSET;

   AddAnimation(self, textures.bang, rect);
}

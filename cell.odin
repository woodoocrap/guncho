package main 

import "vendor:sdl2"

Dir :: enum { Left, UpperLeft, UpperRight, Right, LowerRight, LowerLeft };

Cell :: struct {
   x:        i32
   y:        i32
   rect:     sdl2.Rect,
   pawn:     ^Pawn,

   dangerous: bool
   selected: bool 
};


InitCell :: proc(self: ^Cell, rect: sdl2.Rect, x, y: i32)
{
   self.rect = rect;
   self.x = x;
   self.y = y;
}


RenderCell :: proc(self: ^Cell, render: ^sdl2.Renderer)
{
   if self.selected do sdl2.RenderCopy(render, textures.selection, nil, &self.rect);
   if self.pawn != nil do RenderPawn(self.pawn, render);
}


FindTarget :: proc(self: ^Level, cell: ^Cell, dir: Dir) -> ^Cell
{
   cell := node(self, cell, dir);

   for cell != nil {
      
      if cell.pawn != nil {
         if cell.pawn.type != .Bomb do break;
      }

      cell = node(self, cell, dir);
   }

   return cell;
}


// spaghet to determine neighbors in matrix representation

/*
   0 - 0 - 0
  / \ / \ /
 0 - 0 - 0     
  \ / \ / \  
   0 - 0 - 0
*/

node :: proc(self: ^Level, cell: ^Cell, dir: Dir) -> ^Cell
{
   a, b: i32;
   if cell.y & 1 != 0 do a, b = 0, -1;
   else do a, b = 1, 0;

   switch dir {
      case .UpperLeft:
         if cell.y == 0 do return nil;
         if cell.x == 0 && b != 0 do return nil;
         return &self.grid.cells[cell.y-1][cell.x+b];

      case .UpperRight:
         if cell.y == 0 do return nil;
         if cell.x == self.cols-1 && a == 1 do return nil;
         return &self.grid.cells[cell.y-1][cell.x+a];

      case .LowerLeft:
         if cell.y == self.rows-1 do return nil;
         if cell.x == 0 && b != 0 do return nil;
         return &self.grid.cells[cell.y+1][cell.x+b];

      case .LowerRight:
         if cell.y == self.rows-1 do return nil;
         if cell.x == self.cols-1 && a == 1 do return nil;
         return &self.grid.cells[cell.y+1][cell.x+a];

      case .Left:
         if cell.x == 0 do return nil;
         return &self.grid.cells[cell.y][cell.x-1];

      case .Right:
         if cell.x == self.cols-1 do return nil;
         return &self.grid.cells[cell.y][cell.x+1];
   }

   return nil;
}


IncDir :: proc(dir: Dir) -> Dir { return Dir((int(dir) + 1) % 6); }
DecDir :: proc(dir: Dir) -> Dir { return Dir((int(dir) + 5) % 6); }
RevDir :: proc(dir: Dir) -> Dir { return Dir((int(dir) + 3) % 6); }

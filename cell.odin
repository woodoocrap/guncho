package main 

import "vendor:sdl2"

Dir :: enum { Left, UpperLeft, UpperRight, Right, LowerRight, LowerLeft };

Cell :: struct {
   nodes:    [6]^Cell,
   rect:     sdl2.Rect,
   pawn:     ^Pawn,

   dangerous: bool
   selected: bool 
};


InitCell :: proc(self: ^Cell, rect: sdl2.Rect)
{
   self.rect = rect;
}


BindCell :: proc(self, neighbour: ^Cell, dir: Dir)
{
   opposite := Dir((int(dir) + 3) % 6);
   neighbour.nodes[opposite] = self;
   self.nodes[dir] = neighbour;
}


RenderCell :: proc(self: ^Cell, render: ^sdl2.Renderer)
{
   if self.selected do sdl2.RenderCopy(render, textures.selection, nil, &self.rect);
   if self.pawn != nil do RenderPawn(self.pawn, render);
}


FindTarget :: proc(self: ^Cell, dir: Dir) -> ^Cell
{
   cell := self.nodes[dir];

   for cell != nil {
      
      if cell.pawn != nil {
         if cell.pawn.type != .Bomb do break;
      }

      cell = cell.nodes[dir];
   }

   return cell;
}


IncDir :: proc(dir: Dir) -> Dir { return Dir((int(dir) + 1) % 6); }
DecDir :: proc(dir: Dir) -> Dir { return Dir((int(dir) + 5) % 6); }
RevDir :: proc(dir: Dir) -> Dir { return Dir((int(dir) + 3) % 6); }

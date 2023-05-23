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

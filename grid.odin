package main

import "core:log"
import "vendor:sdl2"
import "vendor:sdl2/image"


Grid :: struct {
   background: ^sdl2.Texture,
   texture:    ^sdl2.Texture,
   
   // since i need to scale it with rest of the grid i put it here
   animations:   [dynamic]^Animation,

   cells:      [][]Cell,
   rect:       sdl2.Rect,
   rows:       i32,
   cols:       i32,
};


CreateGrid :: proc(render: ^sdl2.Renderer, rect: sdl2.Rect, rows, cols: i32) -> ^Grid
{
   self := new(Grid);
   if self == nil do log.fatal("memory allocation failure");

   self.rows = rows;
   self.cols = cols;

   self.rect = rect;
   allocCells(self);
   initCells(self, render);

   return self;
}


allocCells :: proc (self: ^Grid)
{
   self.cells = make([][]Cell, self.rows);
   if self.cells == nil do log.fatal("memory allocation failure");
   
   for i in 0 ..< self.rows {
      self.cells[i] = make([]Cell, self.cols);
      if self.cells[i] == nil do log.fatal("memory allocation failure");
   }
}


initCells :: proc(self: ^Grid, render: ^sdl2.Renderer)
{
   cell_w, cell_h: i32 = 0, 0;
   sdl2.QueryTexture(textures.cell, nil, nil, &cell_w, &cell_h);

   v_step := (cell_h * 3) / 4;
   width := cell_w * self.cols + cell_w/2 + GRID_PADDING;
   height := v_step * self.rows + cell_h / 4 + GRID_PADDING;

   format := u32(sdl2.PixelFormatEnum.RGBA8888);
   self.texture = sdl2.CreateTexture(render, format, .TARGET, width, height);
   if self.texture == nil do log.fatal("failed to create grid texture. ", sdl2.GetError());

   self.background = sdl2.CreateTexture(render, format, .TARGET, width, height);
   if self.background == nil do log.fatal("failed to create grid texture. ", sdl2.GetError());

   cell_rect : sdl2.Rect = { GRID_OFFSET, GRID_OFFSET, cell_w, cell_h };
   dest_rect := cell_rect;
   
   sdl2.SetRenderTarget(render, self.background);
   sdl2.RenderClear(render);

   for i in 0 ..< self.rows {
      dest_rect.x = i & 1 == 0 ? (GRID_OFFSET + cell_w/2) : GRID_OFFSET;
      for j in 0 ..< self.cols {
         //pre-render cells since they dont change so i dont have to draw each every tick
         sdl2.RenderCopy(render, textures.cell, nil, &dest_rect);
         InitCell(&self.cells[i][j], dest_rect, j, i);
         dest_rect.x += cell_w;
      }
      dest_rect.y += v_step;
   }

   sdl2.SetRenderTarget(render, nil);
}


DestroyGrid :: proc(self: ^Grid)
{
   sdl2.DestroyTexture(self.background);
   sdl2.DestroyTexture(self.texture);

   for animation in self.animations do DestroyAnimation(animation);
   delete(self.animations);
   
   for row in self.cells {
      for cell in row {
         if cell.pawn != nil do DestroyPawn(cell.pawn);
      }
   }

   for row in self.cells do delete(row);
   delete(self.cells);
}


RenderGrid :: proc(self: ^Grid, render: ^sdl2.Renderer)
{
   sdl2.SetRenderTarget(render, self.texture);
   sdl2.RenderCopy(render, self.background, nil, nil);

   for i in 0 ..< self.rows {
      for j in 0 ..< self.cols {
         RenderCell(&self.cells[i][j], render);
      }
   }

   for i in 0 ..< len(self.animations) {
      RenderAnimation(self.animations[i], render);
      if self.animations[i].sprite.done do unordered_remove(&self.animations, i);
   }

   sdl2.SetRenderTarget(render, nil);
   sdl2.RenderCopy(render, self.texture, nil, &self.rect);
}

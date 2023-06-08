package main

import "core:log"
import "vendor:sdl2"


PawnType :: enum {
   Ranger, Axe, Cow, Bombot, Bomb, Barrel, Plant, Player
};


Pawn :: struct {
   sprite: ^Sprite,
   rect:   sdl2.Rect,
   type:   PawnType,
   cell:   ^Cell,
   stuned: bool,
   timer:  i32,
};


CreatePawn :: proc(cell: ^Cell, type: PawnType) -> ^Pawn
{
   self := new(Pawn);
   if self == nil do log.fatal("memory allocation failure");
   
   texture: ^sdl2.Texture;

   switch type {
      case .Ranger: texture = textures.ranger;
      case .Axe: texture = textures.axe;
      case .Cow: texture = textures.cow;
      case .Bombot: texture = textures.bombot;
      case .Barrel: texture = textures.barrel;
      case .Bomb: texture = textures.bomb1;
      case .Plant: texture = textures.plant;
      case .Player: texture = textures.player;
   }

   self.rect = cell.rect;
   self.rect.y -= PAWN_OFFSET;

   self.sprite = CreateSprite(texture, PAWN_WIDTH);
   cell.pawn = self;
   self.cell = cell;
   self.type = type;

   return self;
}


DestroyPawn :: proc(self: ^Pawn)
{
   if self.cell != nil do self.cell.pawn = nil;
   DestroySprite(self.sprite);
   free(self);
}


RenderPawn :: proc(self: ^Pawn, render: ^sdl2.Renderer)
{
   RenderSprite(self.sprite, render, &self.rect);
}


//looks ugly, considering redesign
MovePawn :: proc(self: ^Pawn, cell: ^Cell)
{
   self.cell.pawn = nil;

   self.rect = cell.rect;
   self.rect.y -= PAWN_OFFSET;

   self.cell = cell;
   cell.pawn = self;
}

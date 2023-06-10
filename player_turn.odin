package main

import "core:log"
import "core:time"
import "vendor:sdl2"


ProcessAction :: proc(self: ^Game) -> bool
{
   switch self.controls.selected_tool {
      
      case .Move: return MovePlayer(self.level);

      case .Sprint: 
         
         if !MovePlayer(self.level) do return false;

         if self.controls.sprinting { 
            self.controls.cooldowns[Tool.Sprint] = 2;
            self.controls.selected_tool = .Move;
         } else {
            Reselect(self.level, &self.controls);
         }

         self.controls.sprinting = !self.controls.sprinting;
         return !self.controls.sprinting;

      case .Shoot:
         
         dir := self.level.direction;
         // reload
         if self.controls.drum.bullets[dir] == .Empty {
            self.controls.drum.bullets[dir] = .Inactive;
            return true;
         }

         if !hasTarget(self.level.selected_cell) do return false;

         doBang(self.level, self.level.player.cell);
         shotsFired(self.level, self.level.selected_cell);
         if !self.level.over do Reselect(self.level, &self.controls);
         self.controls.drum.bullets[dir] = .Empty;
   
         time.sleep(self.tick * 3);
         if dir == .Left || dir == .UpperLeft || dir == .UpperRight {
            RollDrumLeft(&self.controls);
         } else {
            RollDrumRight(&self.controls);
         }

      case .Punch: 
         if !hasTarget(self.level.selected_cell) do return false;
         self.level.selected_cell.pawn.stuned = true;
         self.controls.cooldowns[Tool.Punch] = 2;
         self.controls.selected_tool = .Move;
         pushPawn(self.level);

      case .BulletHail:
         for dir in Dir {
            if self.controls.drum.bullets[dir] == .Empty do continue;
            self.controls.drum.bullets[dir] = .Empty;
            cell := FindTarget(self.level, self.level.player.cell, dir);
            if cell != nil { 
               doBang(self.level, self.level.player.cell);
               shotsFired(self.level, cell);
            }
            time.sleep(self.tick * 3);
         }
         
         for dir in Dir { 
            self.controls.drum.bullets[dir] = .Inactive;
            time.sleep(self.tick);
         }

         self.controls.cooldowns[Tool.BulletHail] = 4;
         self.controls.selected_tool = .Move;

      case .Wait:
   }

   return true;
}


hasTarget :: proc(cell: ^Cell) -> bool 
{
   if cell == nil do return false
   if cell.pawn == nil do return false;

   return true;
}


//presumes target exists
shotsFired :: proc(self: ^Level, cell: ^Cell)
{  
   pawn := cell.pawn;

   switch pawn.type {
      
      case .Ranger: fallthrough; case .Cow: fallthrough
      case .Axe: fallthrough; case .Bombot:
         DestroyPawn(pawn);
         delete_key(&self.pawns, pawn);
         AddAnimation(self, textures.death, cell.rect);

         self.enemies -= 1;
         if self.enemies == 0 do prepExit(self);
         // TODO: add victory animation
      
      case .Barrel: fallthrough; case .Bomb:
         delete_key(&self.pawns, pawn);
         DestroyPawn(pawn);
         AddAnimation(self, textures.explossion, cell.rect);
         blastRadius(self, cell);

      case .Player: 
         AddAnimation(self, textures.death, cell.rect);
         // TODO: add loss animation
         prepExit(self);

      case .Plant:
   }
}


prepExit :: proc(self: ^Level)
{
   if self.player == nil do return;
   DestroyPawn(self.player);
   self.player = nil;
   self.over = true;
}


blastRadius :: proc(self: ^Level, cell: ^Cell)
{
   for dir in Dir { 
      if hasTarget(node(self, cell, dir)) {
         shotsFired(self, node(self, cell, dir));
      }
   }
}


pushPawn :: proc(self: ^Level)
{
   dir := self.direction;
   cell := self.selected_cell;

   if node(self, cell, dir) == nil do return;
   if node(self, cell, dir).pawn != nil do return;;

   MovePawn(self.selected_cell.pawn, node(self, cell, dir));
}

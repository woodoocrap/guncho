package main

import "core:time"
import "vendor:sdl2"


ProcessAction :: proc(self: ^Game)
{
   switch self.controls.selected_tool {
      
      case .Move: MovePlayer(self.level);

      case .Sprint: 
         
         if self.controls.sprinting { 
            self.controls.cooldowns[Tool.Sprint] = 2;
            self.controls.selected_tool = .Move;
         }

         self.controls.sprinting = !self.controls.sprinting;
         MovePlayer(self.level);

      case .Shoot:
         
         dir := self.level.direction;
         // reload
         if self.controls.drum.bullets[dir] == .Empty {
            self.controls.drum.bullets[dir] = .Inactive;
            return;
         }

         if !hasTarget(self, self.level.selected_cell) do return;

         shotsFired(self, self.level.selected_cell);
         Reselect(self.level, &self.controls);
         self.controls.drum.bullets[dir] = .Empty;
         doBang(self, self.level.player.cell);
   
         time.sleep(self.tick * 3);
         if dir == .Left || dir == .UpperLeft || dir == .UpperRight {
            RollDrumLeft(&self.controls);
         } else {
            RollDrumRight(&self.controls);
         }

      case .Punch: 
         if !hasTarget(self, self.level.selected_cell) do return;
         self.level.selected_cell.pawn.stuned = true;
         self.controls.cooldowns[Tool.Punch] = 2;
         pushPawn(self);

      case .BulletHail:
         for dir in Dir {
            if self.controls.drum.bullets[dir] == .Empty do continue;
            self.controls.drum.bullets[dir] = .Empty;
            cell := FindTarget(self.level.player.cell, dir);
            if cell != nil { 
               doBang(self, self.level.player.cell);
               shotsFired(self, cell);
            }
            time.sleep(self.tick * 3);
         }
         
         for dir in Dir { 
            self.controls.drum.bullets[dir] = .Inactive;
            time.sleep(self.tick);
         }

         self.controls.cooldowns[Tool.BulletHail] = 4;

      case .Wait:
   }
}


hasTarget :: proc(self: ^Game, cell: ^Cell) -> bool 
{
   if cell == nil do return false
   if cell.pawn == nil do return false;

   return true;
}


//presumes target exists
shotsFired :: proc(self: ^Game, cell: ^Cell)
{  
   pawn := cell.pawn;

   switch pawn.type {
      case .Ranger: fallthrough; case .Cow: fallthrough
      case .Axe: fallthrough; case .Bombot:
         DestroyPawn(pawn);
         AddAnimation(self, textures.death, cell.rect);
      
      case .Barrel: 
         DestroyPawn(pawn);
         AddAnimation(self, textures.explossion, cell.rect);
         for dir in Dir { 
            if hasTarget(self, cell.nodes[dir]) {
               shotsFired(self, cell.nodes[dir]);
            }
         }

      case .Player: 
         // play death effect
         // endgame

      case .Plant: return;
      case .Bomb: return;
   }
}


pushPawn :: proc(self: ^Game)
{
   dir := self.level.direction;
   cell := self.level.selected_cell;

   if cell.nodes[dir] == nil do return;
   if cell.nodes[dir].pawn != nil do return;;

   MovePawn(self.level.selected_cell.pawn, cell.nodes[dir]);
}


ProcessInput :: proc(self: ^Game, key: sdl2.Keycode)
{
   #partial switch key {

      case .a: fallthrough; case .LEFT:
         SelectLeft(self.level, &self.controls);

      case .d: fallthrough; case .RIGHT:
         SelectRight(self.level, &self.controls);

      case .s: fallthrough; case .DOWN: 
         SwitchToolDown(&self.controls);
         Reselect(self.level, &self.controls);

      case .w: fallthrough; case .UP:
         SwitchToolUp(&self.controls);
         Reselect(self.level, &self.controls);

      case .SPACE: fallthrough; case .RETURN: 
         ProcessAction(self);
         // enemy turn starts here
         Reselect(self.level, &self.controls);
   }
}

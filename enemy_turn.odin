package main

import "core:log"
import "core:math"
import "core:time"
import "vendor:sdl2"


// TODO: change grid to matrix representation only


triggerBomb :: proc(self: ^Level, bomb: ^Pawn)
{
   cell := bomb.cell;
   DestroyPawn(bomb);

   AddAnimation(self, textures.explossion, cell.rect);
   blastRadius(self, cell);
}


perfectDir :: proc(self: ^Level, x, y: i32) -> Dir
{
   perfect_dir: Dir
   if x > self.player_x {
      if y > self.player_y do perfect_dir = .UpperLeft;
      else if y < self.player_y do perfect_dir = .LowerLeft;
      else do perfect_dir = .Left;
   } else if x < self.player_x {
      if y > self.player_y do perfect_dir = .UpperRight;
      else if y < self.player_y do perfect_dir = .LowerRight;
      else do perfect_dir = .Right;
   } else {
      if y > self.player_y do perfect_dir = .UpperRight;
      else if y < self.player_y do perfect_dir = .LowerRight;
   }

   return perfect_dir;
}

//silly path finding (there wont be too many obstacles so this will do)
MoveCloser :: proc(self: ^Level, x, y: i32)
{
   cell := &self.grid.cells[y][x];
   perfect_dir := perfectDir(self, x, y);

   // match desires with capabilities
   // best case
   if tryMove(cell.pawn, node(self, cell, perfect_dir)) do return;
   
   // meh cases
   for i in 1 ..< 3 {
      dir := Dir((int(perfect_dir) + i) % 6);
      if tryMove(cell.pawn, node(self, cell, dir)) do return;
      dir = Dir((int(perfect_dir) + 6 - i) % 6);
      if tryMove(cell.pawn, node(self, cell, dir)) do return;
   } 

   //worst case
   dir := Dir((i32(perfect_dir) + 3) % 6);
   tryMove(cell.pawn, node(self, cell, dir));

   return;
}



AxeTurn :: proc(self: ^Level, cell: ^Cell, x, y: i32)
{
   if math.abs(x - self.player_x) > 1 || math.abs(y - self.player_y) > 1 {
      MoveCloser(self, x, y);
      return;
   }

   for dir in Dir {
      
      c := node(self, cell, dir);

      if c == nil do continue;
      if c.pawn == nil do continue;
      if c.pawn.type != .Player do continue;
      
      shotsFired(self, c);
   }
}


RangerTurn :: proc(self: ^Level, cell: ^Cell, x, y: i32)
{
   dir := perfectDir(self, x, y);
   target := FindTarget(self, cell, dir);

   if target != nil {
      if target.pawn != nil {
         if target.pawn.type == .Player {
            shotsFired(self, target);
            return;
         }
      }
   }

   MoveCloser(self, x, y);
}


PlaceBomb :: proc(cell: ^Cell)
{
   cell.pawn = CreatePawn(cell, .Bomb);
   cell.pawn.timer = 3;
}


BombotTurn :: proc(self: ^Level, cell: ^Cell, x, y: i32)
{
   if math.abs(x - self.player_x) > 2 || math.abs(y - self.player_y) > 2 {
      MoveCloser(self, x, y);
      return;
   }
   
   dir := perfectDir(self, x, y);
   
   if checkCell(node(self, cell, dir)) { 
      PlaceBomb(node(self, cell, dir));
   } else if checkCell(node(self, cell, IncDir(dir))) {
      PlaceBomb(node(self, cell, IncDir(dir)));
   } else if checkCell(node(self, cell, DecDir(dir))) { 
      PlaceBomb(node(self, cell, DecDir(dir)));
   }
}


checkCell :: proc(cell: ^Cell) -> bool
{
   if cell != nil do if cell.pawn == nil do return true;
   return false;
}


tryMove :: proc(pawn: ^Pawn, cell: ^Cell) -> bool
{
   if !checkCell(cell) do return false;
   MovePawn(pawn, cell);

   return true;;
}


TickBomb :: proc(self: ^Level, bomb: ^Pawn)
{
   if bomb.timer == 0 {
      triggerBomb(self, bomb);
      return;
   }

   bomb.timer -= 1;

   if bomb.timer == 1 do bomb.sprite.texture = textures.bomb2;
   else if bomb.timer == 0 do bomb.sprite.texture = textures.bomb3;
}


EnemyTurn :: proc(self: ^Level)
{
   if self.enemies == 0 {
      // well thats a W
      return;
   }
   
   for i in 0 ..< i32(len(self.grid.cells)) {
      for j in 0 ..< i32(len(self.grid.cells[i])) {
         
         cell := &self.grid.cells[i][j];
         if cell.pawn == nil do continue;

         #partial switch cell.pawn.type {
            //case .Bomb: TickBomb(self, cell.pawn);
            //case .Axe: AxeTurn(self, cell, j, i);
            //case .Bombot: BombotTurn(self, cell, j, i);
            //case .Ranger: RangerTurn(self, cell, j, i);
            // cow 
         }
      }
   }
}

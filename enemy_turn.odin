package main

import "core:log"
import "core:sync"
import "core:math"
import "core:time"
import "vendor:sdl2"


perfectDir :: proc(self: ^Level, x, y: i32) -> Dir
{
   perfect_dir: Dir
   if x > self.player.cell.x {
      if y > self.player.cell.y do perfect_dir = .UpperLeft;
      else if y < self.player.cell.y do perfect_dir = .LowerLeft;
      else do perfect_dir = .Left;
   } else if x < self.player.cell.x {
      if y > self.player.cell.y do perfect_dir = .UpperRight;
      else if y < self.player.cell.y do perfect_dir = .LowerRight;
      else do perfect_dir = .Right;
   } else {
      if y > self.player.cell.y do perfect_dir = .UpperRight;
      else if y < self.player.cell.y do perfect_dir = .LowerRight;
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



AxeTurn :: proc(self: ^Level, cell: ^Cell)
{
   x, y := cell.x, cell.y
   if math.abs(x - self.player.cell.x) > 1 || math.abs(y - self.player.cell.y) > 1 {
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


RangerTurn :: proc(self: ^Level, cell: ^Cell)
{
   x, y := cell.x, cell.y
   dir := perfectDir(self, x, y);
   target := FindTarget(self, cell, dir);

   if target != nil {
      if target.pawn != nil {
         if target.pawn.type == .Player {
            doBang(self, cell);
            shotsFired(self, target);
            return;
         }
      }
   }

   MoveCloser(self, x, y);
}


CowTurn :: proc(self: ^Level, cell: ^Cell)
{
   x, y := cell.x, cell.y
   dir := perfectDir(self, x, y);
   target := FindTarget(self, cell, dir);

   if target != nil {
      if target.pawn != nil {
         if target.pawn.type == .Player {

            AnimateCharge(cell.pawn, target);
            shotsFired(self, target);
            MovePawn(cell.pawn, target);

            return;
         }
      }
   }

   MoveCloser(self, x, y);
}


PlaceBomb :: proc(self: ^Level, cell: ^Cell)
{
   bomb := CreatePawn(cell, .Bomb);
   cell.pawn = bomb;
   self.pawns[bomb] = true;
   cell.pawn.timer = 3;
}


BombotTurn :: proc(self: ^Level, cell: ^Cell)
{
   x, y := cell.x, cell.y
   if math.abs(x - self.player.cell.x) > 2 || math.abs(y - self.player.cell.y) > 2 {
      MoveCloser(self, x, y);
      return;
   }
   
   dir := perfectDir(self, x, y);
   
   if checkCell(node(self, cell, dir)) { 
      PlaceBomb(self, node(self, cell, dir));
   } else if checkCell(node(self, cell, IncDir(dir))) {
      PlaceBomb(self, node(self, cell, IncDir(dir)));
   } else if checkCell(node(self, cell, DecDir(dir))) { 
      PlaceBomb(self, node(self, cell, DecDir(dir)));
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
      shotsFired(self, bomb.cell);
      return;
   }

   bomb.timer -= 1;
   texture := bomb.timer == 2 ? textures.bomb1 : bomb.timer == 1 ? textures.bomb2 : textures.bomb3;
   //swap sprite
   sync.mutex_lock(&mutex);
      DestroySprite(bomb.sprite);
      bomb.sprite = CreateSprite(texture, PAWN_WIDTH, true);
   sync.mutex_unlock(&mutex);
}


EnemyTurn :: proc(self: ^Level)
{
   for pawn in self.pawns { 
      cell := pawn.cell;
      
      if pawn.stuned && pawn.type != .Bomb {
         pawn.stuned = false;
         continue;
      }

      #partial switch cell.pawn.type {
         case .Bomb: TickBomb(self, cell.pawn);
         case .Axe: AxeTurn(self, cell);
         case .Bombot: BombotTurn(self, cell);
         case .Ranger: RangerTurn(self, cell);
         case .Cow: CowTurn(self, cell);
      }
      if self.over do return;
   }
}

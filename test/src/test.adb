with HAL; use HAL;
with Board;

--  Paints a test pattern once and holds it: red ramps left to right, blue
--  ramps top to bottom, and a green square marks the (0, 0) corner. If the
--  square is anywhere but top left the offsets are wrong, and if the ramps
--  come out blue and red the panel is BGR.
procedure Test is
   use Board.LCD;
begin
   Board.Initialize;
   Board.LCD.Initialize;

   for Y in Row loop
      for X in Column loop
         Set_Pixel (X, Y,
            (R => UInt5 (Natural (X) * 31 / (Width - 1)),
             G => 0,
             B => UInt5 (Natural (Y) * 31 / (Height - 1))));
      end loop;
   end loop;

   for Y in Row range 0 .. 15 loop
      for X in Column range 0 .. 15 loop
         Set_Pixel (X, Y, (R => 0, G => 63, B => 0));
      end loop;
   end loop;

   loop
      null;
   end loop;
end Test;

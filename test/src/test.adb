with Board;

procedure Test is
begin
   Board.Initialize;
   Board.LCD.Initialize;
   loop
      Board.LCD.Set_Pixel (0, 0, (31, 0, 0));
      Board.LCD.Update;
   end loop;
end Test;

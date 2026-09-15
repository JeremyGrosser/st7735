with HAL; use HAL;
with RP.Timer; use RP.Timer;
with Board;

--  Cycles through a set of animations, forever:
--
--    Alignment  red ramps along X, blue along Y, a green square at (0, 0) and
--               a white one pixel border. Any noise or missing border along
--               an edge means the offsets in Board are wrong.
--    Boxes      squares bouncing off the edges, erasing only the strips they
--               leave behind.
--    Plasma     overlapping sine waves mapped through a rainbow, drawn into a
--               centered square one row at a time.
--    Worm       a rainbow chain of squares tracing a Lissajous curve.
procedure Test is
   use Board.LCD;

   Black : constant Color := (0, 0, 0);
   White : constant Color := (31, 63, 31);

   Scene_Time : constant Time := Milliseconds (8_000);

   --  One period of a sine wave, 0 .. 255 centered on 128.
   Sine : constant array (UInt8) of Natural :=
      (
       128, 131, 134, 137, 140, 143, 146, 149, 152, 155, 158, 162,
       165, 167, 170, 173, 176, 179, 182, 185, 188, 190, 193, 196,
       198, 201, 203, 206, 208, 211, 213, 215, 218, 220, 222, 224,
       226, 228, 230, 232, 234, 235, 237, 238, 240, 241, 243, 244,
       245, 246, 248, 249, 250, 250, 251, 252, 253, 253, 254, 254,
       254, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 253,
       253, 252, 251, 250, 250, 249, 248, 246, 245, 244, 243, 241,
       240, 238, 237, 235, 234, 232, 230, 228, 226, 224, 222, 220,
       218, 215, 213, 211, 208, 206, 203, 201, 198, 196, 193, 190,
       188, 185, 182, 179, 176, 173, 170, 167, 165, 162, 158, 155,
       152, 149, 146, 143, 140, 137, 134, 131, 128, 124, 121, 118,
       115, 112, 109, 106, 103, 100,  97,  93,  90,  88,  85,  82,
        79,  76,  73,  70,  67,  65,  62,  59,  57,  54,  52,  49,
        47,  44,  42,  40,  37,  35,  33,  31,  29,  27,  25,  23,
        21,  20,  18,  17,  15,  14,  12,  11,  10,   9,   7,   6,
         5,   5,   4,   3,   2,   2,   1,   1,   1,   0,   0,   0,
         0,   0,   0,   0,   1,   1,   1,   2,   2,   3,   4,   5,
         5,   6,   7,   9,  10,  11,  12,  14,  15,  17,  18,  20,
        21,  23,  25,  27,  29,  31,  33,  35,  37,  40,  42,  44,
        47,  49,  52,  54,  57,  59,  62,  65,  67,  70,  73,  76,
        79,  82,  85,  88,  90,  93,  97, 100, 103, 106, 109, 112,
       115, 118, 121, 124);

   --  0 .. 191 walks red, green, blue and back to red; wraps outside that.
   function Hue
      (H : Natural)
      return Color
   is
      F : constant Natural := H mod 64;
   begin
      case (H mod 192) / 64 is
         when 0 => return (R => UInt5 (31 - F / 2), G => UInt6 (F), B => 0);
         when 1 => return (R => 0, G => UInt6 (63 - F), B => UInt5 (F / 2));
         when others =>
            return (R => UInt5 (F / 2), G => 0, B => UInt5 (31 - F / 2));
      end case;
   end Hue;

   function Sin
      (I : Integer)
      return Natural
   is (Sine (UInt8 (I mod 256)));

   --  Fill in screen coordinates that may be partly or wholly off screen.
   procedure Fill_Clipped
      (X, Y, W, H : Integer;
       C          : Color)
   is
      X1 : constant Integer := Integer'Max (X, 0);
      Y1 : constant Integer := Integer'Max (Y, 0);
      X2 : constant Integer := Integer'Min (X + W - 1, Width - 1);
      Y2 : constant Integer := Integer'Min (Y + H - 1, Height - 1);
   begin
      if X1 <= X2 and then Y1 <= Y2 then
         Fill (Column (X1), Column (X2), Row (Y1), Row (Y2), C);
      end if;
   end Fill_Clipped;

   procedure Wait_Frame
      (Next : in out Time;
       Ms   : Natural)
   is
   begin
      Next := Next + Milliseconds (Ms);
      if Clock < Next then
         Busy_Wait_Until (Next);
      else
         Next := Clock;
      end if;
   end Wait_Frame;

   procedure Alignment is
      Line : Color_Array (0 .. Width - 1);
   begin
      Start_Pixels (Column'First, Column'Last, Row'First, Row'Last);
      for Y in 0 .. Height - 1 loop
         for X in Line'Range loop
            Line (X) :=
               (R => UInt5 (X * 31 / (Width - 1)),
                G => 0,
                B => UInt5 (Y * 31 / (Height - 1)));
         end loop;
         Put_Pixels (Line);
      end loop;
      End_Pixels;

      Fill (Column'First, Column'Last, Row'First, Row'First, White);
      Fill (Column'First, Column'Last, Row'Last, Row'Last, White);
      Fill (Column'First, Column'First, Row'First, Row'Last, White);
      Fill (Column'Last, Column'Last, Row'First, Row'Last, White);
      Fill (1, 16, 1, 16, (R => 0, G => 63, B => 0));

      Board.Delay_Milliseconds (3_000);
   end Alignment;

   procedure Boxes is
      type Box is record
         X, Y, DX, DY, Size : Integer;
         C                  : Color;
      end record;

      Items : array (1 .. 6) of Box :=
         ((10, 10, 2, 3, 20, Hue (0)),
          (60, 30, -3, 2, 16, Hue (32)),
          (90, 100, 3, -2, 24, Hue (64)),
          (20, 120, -2, -3, 12, Hue (96)),
          (70, 70, 1, 4, 18, Hue (128)),
          (40, 50, 4, 1, 14, Hue (160)));

      Deadline : constant Time := Clock + Scene_Time;
      Next     : Time := Clock;
   begin
      Clear;
      while Clock < Deadline loop
         for B of Items loop
            declare
               OX : constant Integer := B.X;
               OY : constant Integer := B.Y;
            begin
               B.X := B.X + B.DX;
               B.Y := B.Y + B.DY;
               if B.X < 0 or else B.X + B.Size > Width then
                  B.DX := -B.DX;
                  B.X := OX + B.DX;
               end if;
               if B.Y < 0 or else B.Y + B.Size > Height then
                  B.DY := -B.DY;
                  B.Y := OY + B.DY;
               end if;

               --  The old and new squares overlap, so only the strips the
               --  square moved off of need clearing.
               if B.X > OX then
                  Fill_Clipped (OX, OY, B.X - OX, B.Size, Black);
               elsif B.X < OX then
                  Fill_Clipped (B.X + B.Size, OY, OX - B.X, B.Size, Black);
               end if;
               if B.Y > OY then
                  Fill_Clipped (OX, OY, B.Size, B.Y - OY, Black);
               elsif B.Y < OY then
                  Fill_Clipped (OX, B.Y + B.Size, B.Size, OY - B.Y, Black);
               end if;
            end;
         end loop;

         --  Draw after all the erasing, so one box's trail can't cut into
         --  another box.
         for B of Items loop
            Fill_Clipped (B.X, B.Y, B.Size, B.Size, B.C);
         end loop;

         Wait_Frame (Next, 20);
      end loop;
   end Boxes;

   procedure Plasma is
      Size : constant := 96;
      X0   : constant := (Width - Size) / 2;
      Y0   : constant := (Height - Size) / 2;

      Line     : Color_Array (0 .. Size - 1);
      Deadline : constant Time := Clock + Scene_Time;
      T        : Natural := 0;
   begin
      Clear;
      Fill (X0 - 2, X0 + Size + 1, Y0 - 2, Y0 - 2, White);
      Fill (X0 - 2, X0 + Size + 1, Y0 + Size + 1, Y0 + Size + 1, White);
      Fill (X0 - 2, X0 - 2, Y0 - 2, Y0 + Size + 1, White);
      Fill (X0 + Size + 1, X0 + Size + 1, Y0 - 2, Y0 + Size + 1, White);

      while Clock < Deadline loop
         Start_Pixels (X0, X0 + Size - 1, Y0, Y0 + Size - 1);
         for Y in 0 .. Size - 1 loop
            declare
               RowWave : constant Natural :=
                  Sin (Y * 4 - T * 3) + Sin (Y * 2 + Sin (T * 2) / 2);
            begin
               for X in Line'Range loop
                  Line (X) := Hue
                     ((RowWave + Sin (X * 3 + T * 5) + Sin (X + Y + T)) / 4
                      + T * 2);
               end loop;
            end;
            Put_Pixels (Line);
         end loop;
         End_Pixels;

         T := T + 1;
      end loop;
   end Plasma;

   procedure Worm is
      Seg  : constant := 10;
      Len  : constant := 32;

      type Point is record
         X, Y : Integer;
      end record;

      Trail    : array (0 .. Len - 1) of Point := (others => (-Seg, -Seg));
      Head     : Natural := 0;
      Deadline : constant Time := Clock + Scene_Time;
      Next     : Time := Clock;
      T        : Natural := 0;
   begin
      Clear;
      while Clock < Deadline loop
         --  Erase the tail, then move the head into its slot.
         Fill_Clipped (Trail (Head).X, Trail (Head).Y, Seg, Seg, Black);
         Trail (Head) :=
            (X => Sin (T * 3) * (Width - Seg) / 256,
             Y => Sin (T * 2 + 64) * (Height - Seg) / 256);

         --  Redraw oldest to newest so the head is on top, with the colors
         --  rippling back along the body.
         for I in 1 .. Len loop
            declare
               P : constant Point := Trail ((Head + I) mod Len);
            begin
               Fill_Clipped (P.X, P.Y, Seg, Seg, Hue (T * 4 + I * 6));
            end;
         end loop;

         Head := (Head + 1) mod Len;
         T := T + 1;
         Wait_Frame (Next, 15);
      end loop;
   end Worm;

begin
   Board.Initialize;
   Board.LCD.Initialize;

   loop
      Alignment;
      Boxes;
      Plasma;
      Worm;
   end loop;
end Test;

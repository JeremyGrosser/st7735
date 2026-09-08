package body ST7735 is
   FB : UInt16_Array (1 .. Width * Height);

   procedure Initialize is
   begin
      Clear;
      Set_CS (False);
      Set_DC (False);
      SPI_Write (16#11#);
      SPI_Write (16#B1#);
      Set_DC (True);
      SPI_Write (16#01#);
      SPI_Write (16#2C#);
      SPI_Write (16#2D#);
      Set_DC (False);
      SPI_Write (16#B2#);
   end Initialize;

   procedure Clear is
   begin
      FB := (others => 0);
   end Clear;

   function To_RGB565
      (C : Color)
      return UInt16
   is
   begin
      return Shift_Left ((31 * (UInt16 (C.R) + 4)) / 255, 11) or
             Shift_Left ((63 * (UInt16 (C.G) + 2)) / 255, 5) or
                        ((31 * (UInt16 (C.B) + 4)) / 255);
   end To_RGB565;

   procedure Set_Pixel
      (X : Column;
       Y : Row;
       C : Color)
   is
   begin
      FB ((Natural (Y) * Width) + Natural (X)) := To_RGB565 (C);
   end Set_Pixel;

   procedure Update is
   begin
      Set_CS (False);
      Set_DC (True);
      for D of FB loop
         SPI_Write (UInt8 (Shift_Right (D, 8)));
         SPI_Write (UInt8 (D and 16#FF#));
      end loop;
      Set_CS (True);
   end Update;
end ST7735;

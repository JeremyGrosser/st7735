with HAL; use HAL;

generic
   with procedure Set_CS (High : Boolean);
   with procedure Set_DC (High : Boolean);
   with procedure SPI_Write (Data : UInt8);
package ST7735 is
   Width  : constant := 128;
   Height : constant := 160;

   type Column is range 0 .. Width - 1;
   type Row    is range 0 .. Height - 1;

   type Color is record
      R : UInt5;
      G : UInt6;
      B : UInt5;
   end record;

   procedure Initialize;
   procedure Clear;
   procedure Set_Pixel
      (X : Column;
       Y : Row;
       C : Color);
   procedure Update;
end ST7735;

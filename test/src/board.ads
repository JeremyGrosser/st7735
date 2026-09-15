with ST7735;
with HAL;

--  A 1.8" 128x160 "green tab" ST7735S module on SPI0 of a Raspberry Pi Pico:
--
--    GP2 -> SCK, GP3 -> SDA/MOSI, GP4 -> RST, GP5 -> CS, GP6 -> DC,
--    GP7 -> BLK (backlight)
package Board is
   procedure Initialize;

   procedure Set_CS
      (High : Boolean);

   procedure Set_DC
      (High : Boolean);

   procedure SPI_Write
      (Data : HAL.UInt8_Array);

   procedure Delay_Milliseconds
      (Ms : Natural);

   package LCD is new ST7735
      (Set_CS             => Set_CS,
       Set_DC             => Set_DC,
       SPI_Write          => SPI_Write,
       Delay_Milliseconds => Delay_Milliseconds,
       --  This panel's visible area starts at column 2, row 1 of frame
       --  memory. With (0, 0) the last two columns and last row show
       --  uninitialized noise along the edges.
       X_Offset           => 2,
       Y_Offset           => 1);
end Board;

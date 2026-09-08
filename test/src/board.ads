with ST7735;
with HAL;

--  A 128x160 ST7735R module on SPI0 of a Raspberry Pi Pico:
--
--    GP2 -> SCK, GP3 -> SDA/MOSI, GP5 -> CS, GP6 -> DC
--
--  RESX is assumed tied high on the module; the driver resets in software.
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
       Delay_Milliseconds => Delay_Milliseconds);
end Board;

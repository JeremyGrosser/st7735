with ST7735;
with HAL;

package Board is
   procedure Initialize;

   procedure Set_CS
      (High : Boolean);

   procedure Set_DC
      (High : Boolean);

   procedure SPI_Write
      (Data : HAL.UInt8);

   package LCD is new ST7735
      (Set_CS    => Set_CS,
       Set_DC    => Set_DC,
       SPI_Write => SPI_Write);
end Board;

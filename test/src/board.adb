with RP.Clock;
with RP.GPIO;
with HAL.SPI;
with RP.SPI;
with RP.Device;
with Pico;

package body Board is
   Port : RP.SPI.SPI_Port renames RP.Device.SPI_0;

   procedure Initialize is
   begin
      RP.Clock.Initialize (Pico.XOSC_Frequency);
      RP.SPI.Configure (Port);
      RP.SPI.Set_Speed (Port, 5_000_000); --  faster probably ok
   end Initialize;

   procedure Set_CS
      (High : Boolean)
   is
   begin
      if High then
         RP.GPIO.Set (Pico.GP5);
      else
         RP.GPIO.Clear (Pico.GP5);
      end if;
   end Set_CS;

   procedure Set_DC
      (High : Boolean)
   is
   begin
      if High then
         RP.GPIO.Set (Pico.GP6);
      else
         RP.GPIO.Clear (Pico.GP6);
      end if;
   end Set_DC;

   procedure SPI_Write
      (Data : HAL.UInt8)
   is
      Status : HAL.SPI.SPI_Status;
   begin
      RP.SPI.Transmit
         (This    => Port,
          Data    => HAL.SPI.SPI_Data_8b'(1 => Data),
          Status  => Status,
          Timeout => 0);
   end SPI_Write;
end Board;

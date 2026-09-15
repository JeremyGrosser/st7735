with RP.Clock;
with RP.GPIO;
with RP.SPI;
with RP.Timer;
with HAL.SPI;
with RP2040_SVD.SPI;
with Pico;

package body Board is
   Port : RP.SPI.SPI_Port (0, RP2040_SVD.SPI.SPI0_Periph'Access);

   SCK : RP.GPIO.GPIO_Point renames Pico.GP2;
   SDA : RP.GPIO.GPIO_Point renames Pico.GP3;
   RST : RP.GPIO.GPIO_Point renames Pico.GP4;
   CS  : RP.GPIO.GPIO_Point renames Pico.GP5;
   DC  : RP.GPIO.GPIO_Point renames Pico.GP6;
   BLK : RP.GPIO.GPIO_Point renames Pico.GP7;

   procedure Initialize is
   begin
      RP.Clock.Initialize (Pico.XOSC_Frequency);

      SCK.Configure (RP.GPIO.Output, RP.GPIO.Floating, RP.GPIO.SPI);
      SDA.Configure (RP.GPIO.Output, RP.GPIO.Floating, RP.GPIO.SPI);

      --  CS and DC are driven by the driver rather than the SPI peripheral,
      --  so they stay on SIO. Both idle high.
      CS.Configure (RP.GPIO.Output);
      DC.Configure (RP.GPIO.Output);

      RST.Configure (RP.GPIO.Output);
      RP.GPIO.Clear (RST);
      Delay_Milliseconds (1);
      RP.GPIO.Set (RST);

      BLK.Configure (RP.GPIO.Output);
      RP.GPIO.Set (BLK);

      Set_CS (True);
      Set_DC (True);

      --  Mode 0, which is what the ST7735R samples on: SCK idles low and data
      --  is latched on the rising edge.
      RP.SPI.Configure (Port,
         (Baud     => 15_000_000,
          Polarity => RP.SPI.Active_Low,
          Phase    => RP.SPI.Rising_Edge,
          others   => <>));
   end Initialize;

   procedure Set_CS
      (High : Boolean)
   is
   begin
      if High then
         RP.GPIO.Set (CS);
      else
         RP.GPIO.Clear (CS);
      end if;
   end Set_CS;

   procedure Set_DC
      (High : Boolean)
   is
   begin
      if High then
         RP.GPIO.Set (DC);
      else
         RP.GPIO.Clear (DC);
      end if;
   end Set_DC;

   procedure SPI_Write
      (Data : HAL.UInt8_Array)
   is
      Status : HAL.SPI.SPI_Status;
   begin
      --  Blocking is on in the configuration above, so this returns only once
      --  the last bit has left the shift register.
      RP.SPI.Transmit
         (This    => Port,
          Data    => HAL.SPI.SPI_Data_8b (Data),
          Status  => Status,
          Timeout => 0);
   end SPI_Write;

   procedure Delay_Milliseconds
      (Ms : Natural)
   is
      use type RP.Timer.Time;
   begin
      RP.Timer.Busy_Wait_Until (RP.Timer.Clock + RP.Timer.Milliseconds (Ms));
   end Delay_Milliseconds;
end Board;

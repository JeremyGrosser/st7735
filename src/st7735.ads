with HAL; use HAL;

--  Driver for the Sitronix ST7735R TFT controller in 16 bit/pixel mode over a
--  4-wire serial (MCU) interface. Register and timing references in the body
--  are to the ST7735R datasheet, V0.2, 2009-08-05.
generic
   --  Chip select. The display is selected while CS is low, so Set_CS (False)
   --  begins a transaction and Set_CS (True) ends it.
   with procedure Set_CS (High : Boolean);

   --  Data/command select. Low while a command byte is on the bus, high while
   --  its parameters or pixel data are.
   with procedure Set_DC (High : Boolean);

   --  Write Data to the display, MSB first, mode 0 (CPOL = 0, CPHA = 0), at
   --  no more than 15 MHz. Must not return until the last bit has been
   --  clocked out, as CS and DC move immediately afterwards.
   with procedure SPI_Write (Data : UInt8_Array);

   --  Busy-wait at least Ms milliseconds. Initialize needs this for the reset
   --  and sleep-out settling times, which the controller does not signal.
   with procedure Delay_Milliseconds (Ms : Natural);

   --  Frame memory is 132x162, one row and column larger than the panel, so
   --  some modules are wired with the visible area offset into it. A "green
   --  tab" 128x160 module typically needs (2, 1); a "red tab" one needs
   --  (0, 0).
   X_Offset : Natural := 0;
   Y_Offset : Natural := 0;

   --  True if the panel's subpixels are wired blue-green-red rather than
   --  red-green-blue. If red and blue come out swapped, flip this.
   BGR : Boolean := False;
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

   --  Reset the controller, configure it for 16 bit/pixel, and turn the
   --  display on showing a blank screen. If the module's RESX pin is wired to
   --  a GPIO, drive it high before calling this. Takes about 250 ms.
   procedure Initialize;

   --  Set every pixel of the framebuffer to black. Not visible until Update.
   procedure Clear;

   --  Write one pixel of the framebuffer. Not visible until Update.
   procedure Set_Pixel
      (X : Column;
       Y : Row;
       C : Color);

   --  Send the whole framebuffer to the display.
   procedure Update;
end ST7735;

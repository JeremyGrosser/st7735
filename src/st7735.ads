with HAL; use HAL;

--  Driver for the Sitronix ST7735R and ST7735S TFT controllers in 16 bit/pixel mode over a
--  4-wire serial (MCU) interface. Register and timing references in the body
--  are to the ST7735R datasheet, V0.2, 2009-08-05.
--
--  Drawing goes straight out to the controller's frame memory; nothing is
--  buffered on this side, so the driver holds no state and needs no RAM.
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

   --  Frame memory can be up to 132x162, larger than the 128x160 panel, and
   --  where the glass is bonded within it varies by module. Nothing on the
   --  bus reveals this -- these modules have no SDO pin, and the ID commands
   --  would only name the controller anyway -- so it is set here. The
   --  protective film tab color is a rough guide:
   --
   --    Green tab   X_Offset => 2, Y_Offset => 1
   --    Red tab     X_Offset => 0, Y_Offset => 0, BGR => True
   --    Black tab   X_Offset => 0, Y_Offset => 0
   --
   --  Vendors are not consistent, so check with a test pattern: noise along
   --  the right or bottom edge means the offsets are too small, a missing
   --  row or column at the left or top means they are too large.
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

   --  Component intensities. Set_Pixel packs these into the RGB565 pixel the
   --  controller expects.
   type Color is record
      R : UInt5;
      G : UInt6;
      B : UInt5;
   end record;

   --  Reset the controller, configure it for 16 bit/pixel, blank the screen
   --  and turn the display on. If the module's RESX pin is wired to a GPIO,
   --  drive it high before calling this. Takes about 250 ms.
   procedure Initialize;

   type Color_Array is array (Natural range <>) of Color;

   --  Set every pixel to black.
   procedure Clear;

   --  Set every pixel in the rectangle X1 .. X2, Y1 .. Y2 to C, in a single
   --  memory write.
   procedure Fill
      (X1, X2 : Column;
       Y1, Y2 : Row;
       C      : Color);

   --  Stream pixels into the rectangle X1 .. X2, Y1 .. Y2. Start_Pixels opens
   --  the memory write, each Put_Pixels call sends the next Colors'Length
   --  pixels left to right, top to bottom, and End_Pixels closes it. Put_Pixels
   --  packs Colors into a buffer on the stack of twice its length, so send a
   --  row or so at a time rather than a whole screen.
   procedure Start_Pixels
      (X1, X2 : Column;
       Y1, Y2 : Row);

   procedure Put_Pixels
      (Colors : Color_Array);

   procedure End_Pixels;

   --  Set one pixel. This is a whole transaction against the controller --
   --  an address window and a memory write, thirteen bytes on the bus -- so
   --  it is cheap for scattered pixels and slow for large areas.
   procedure Set_Pixel
      (X : Column;
       Y : Row;
       C : Color);
end ST7735;

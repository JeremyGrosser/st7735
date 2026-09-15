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

   --  True for the original ST7735 (sometimes marked ST7735B), sold on
   --  "blue tab" modules. It needs different power and VCOM settings from
   --  the ST7735R and ST7735S, which take identical commands.
   ST7735B : Boolean := False;

   --  Frame memory can be up to 132x162, larger than the panel, and where the
   --  glass is bonded within it varies by module. Nothing on the bus reveals
   --  this -- these modules have no SDO pin, and the ID commands would only
   --  name the controller anyway -- so it is set here. The protective film
   --  tab color is a rough guide, following Adafruit's naming. Offsets are
   --  for this driver's orientation, which is Adafruit's rotation 2:
   --
   --    Module                  Controller  X_Offset  Y_Offset  BGR
   --    1.8" 128x160 green tab  R or S      2         1         True
   --    1.8" 128x160 red tab    R or S      0         0         True
   --    1.8" 128x160 black tab  R or S      0         0         False
   --    1.8" 128x160 blue tab   B           0         0         True
   --
   --  Adafruit also sells these, which need Width and Height changed below:
   --
   --    1.44" 128x128 green tab R or S      2         1         True
   --    0.96" 80x160 mini       R or S      24        0         False
   --    0.96" 80x160 mini with  R or S      26        1         True
   --      the plug-in FPC
   --
   --  The 1.44" panel sits 3 rows down from the other end of frame memory,
   --  so its Y_Offset becomes 3 if the rows are ever mirrored. The plug-in
   --  mini's glass is inverted: it needs INVON where Initialize sends INVOFF,
   --  or every color comes out as its complement.
   --
   --  Vendors are not consistent, so check with a test pattern: noise along
   --  the right or bottom edge means the offsets are too small, a missing
   --  row or column at the left or top means they are too large, and swapped
   --  red and blue means BGR is wrong.
   X_Offset : Natural := 0;
   Y_Offset : Natural := 0;

   --  True if the panel's subpixels are wired blue-green-red rather than
   --  red-green-blue.
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

package body ST7735 is
   --  System function commands, datasheet tables 10.1.1 through 10.1.3
   SWRESET : constant := 16#01#;  --  Software reset
   SLPOUT  : constant := 16#11#;  --  Sleep out & booster on
   NORON   : constant := 16#13#;  --  Partial off (normal)
   INVOFF  : constant := 16#20#;  --  Display inversion off
   DISPON  : constant := 16#29#;  --  Display on
   CASET   : constant := 16#2A#;  --  Column address set
   RASET   : constant := 16#2B#;  --  Row address set
   RAMWR   : constant := 16#2C#;  --  Memory write
   MADCTL  : constant := 16#36#;  --  Memory data access control
   COLMOD  : constant := 16#3A#;  --  Interface pixel format

   --  COLMOD parameter. 16 bit/pixel is IFPF = 101; datasheet 10.1.30 note 2
   --  asks for 55h, which sets the RGB interface format to match, when 16
   --  bit/pixel data is written to frame memory.
   COLMOD_16BPP : constant UInt8 := 16#55#;

   --  MADCTL D3, the RGB/BGR order bit: 1 selects BGR (datasheet 10.1.27).
   MADCTL_BGR : constant UInt8 := 2#0000_1000#;

   No_Data : constant UInt8_Array (1 .. 0) := (1 .. 0 => 0);

   --  One pixel per two bytes, in the order the controller expects them:
   --  RGB565, high byte first. Update can then hand the whole thing to
   --  SPI_Write untouched.
   FB : UInt8_Array (0 .. (Width * Height * 2) - 1);

   procedure Command
      (Cmd  : UInt8;
       Data : UInt8_Array := No_Data);

   procedure Set_Address_Window;

   function To_RGB565
      (C : Color)
      return UInt16;

   procedure Command
      (Cmd  : UInt8;
       Data : UInt8_Array := No_Data)
   is
   begin
      Set_CS (False);
      Set_DC (False);
      SPI_Write ((1 => Cmd));
      if Data'Length > 0 then
         Set_DC (True);
         SPI_Write (Data);
      end if;
      Set_CS (True);
   end Command;

   --  Point the frame memory address counter at the visible area, so that the
   --  RAMWR in Update walks it from the top left to the bottom right.
   procedure Set_Address_Window is
      XS : constant UInt16 := UInt16 (X_Offset);
      XE : constant UInt16 := UInt16 (X_Offset + Width - 1);
      YS : constant UInt16 := UInt16 (Y_Offset);
      YE : constant UInt16 := UInt16 (Y_Offset + Height - 1);
   begin
      Command (CASET,
         (UInt8 (Shift_Right (XS, 8)), UInt8 (XS and 16#FF#),
          UInt8 (Shift_Right (XE, 8)), UInt8 (XE and 16#FF#)));
      Command (RASET,
         (UInt8 (Shift_Right (YS, 8)), UInt8 (YS and 16#FF#),
          UInt8 (Shift_Right (YE, 8)), UInt8 (YE and 16#FF#)));
   end Set_Address_Window;

   procedure Initialize is
   begin
      Clear;

      --  Both of these need 120 ms before the next command can be sent: the
      --  reset to load register defaults, the sleep out for the supply
      --  voltages and oscillator to settle (datasheet 10.1.2 and 10.1.11).
      Command (SWRESET);
      Delay_Milliseconds (120);
      Command (SLPOUT);
      Delay_Milliseconds (120);

      --  The reset above already loaded working values into the frame rate,
      --  inversion, power and gamma registers -- see the Default rows of
      --  datasheet sections 10.2.1 onward -- so only the pixel format and
      --  memory access order are left to set.
      Command (COLMOD, (1 => COLMOD_16BPP));
      Command (MADCTL, (1 => (if BGR then MADCTL_BGR else 0)));

      Command (INVOFF);
      Command (NORON);
      --  NORON and DISPON take effect at the next V-sync (datasheet 10.1
      --  note 4), which is at most one frame away.
      Delay_Milliseconds (10);
      Command (DISPON);

      --  Frame memory contents are undefined after reset, so push the blank
      --  framebuffer before anything can be seen.
      Update;
   end Initialize;

   procedure Clear is
   begin
      FB := (others => 0);
   end Clear;

   function To_RGB565
      (C : Color)
      return UInt16
   is (Shift_Left (UInt16 (C.R), 11) or
       Shift_Left (UInt16 (C.G), 5) or
                   UInt16 (C.B));

   procedure Set_Pixel
      (X : Column;
       Y : Row;
       C : Color)
   is
      I : constant Natural := ((Natural (Y) * Width) + Natural (X)) * 2;
      P : constant UInt16 := To_RGB565 (C);
   begin
      FB (I)     := UInt8 (Shift_Right (P, 8));
      FB (I + 1) := UInt8 (P and 16#FF#);
   end Set_Pixel;

   procedure Update is
   begin
      Set_Address_Window;
      Command (RAMWR, FB);
   end Update;
end ST7735;

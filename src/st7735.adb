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

   --  One row of black, the unit Clear streams in.
   Blank_Row : constant UInt8_Array (0 .. (Width * 2) - 1) := (others => 0);

   procedure Start_Command (Cmd : UInt8);
   procedure Write_Data (Data : UInt8_Array);
   procedure End_Command;

   procedure Command
      (Cmd  : UInt8;
       Data : UInt8_Array := No_Data);

   procedure Set_Address_Window
      (X1, X2 : Column;
       Y1, Y2 : Row);

   --  CS is held low for the whole of a command, from its opcode through the
   --  last byte of its data, so that Clear can stream a screenful of pixels
   --  into one memory write a row at a time.
   procedure Start_Command (Cmd : UInt8) is
   begin
      Set_CS (False);
      Set_DC (False);
      SPI_Write ((1 => Cmd));
      Set_DC (True);
   end Start_Command;

   procedure Write_Data (Data : UInt8_Array) is
   begin
      SPI_Write (Data);
   end Write_Data;

   procedure End_Command is
   begin
      Set_CS (True);
   end End_Command;

   procedure Command
      (Cmd  : UInt8;
       Data : UInt8_Array := No_Data)
   is
   begin
      Start_Command (Cmd);
      if Data'Length > 0 then
         Write_Data (Data);
      end if;
      End_Command;
   end Command;

   --  Confine writes to the given rectangle. The controller walks it left to
   --  right, top to bottom, and wraps back to X1, Y1 at the end.
   procedure Set_Address_Window
      (X1, X2 : Column;
       Y1, Y2 : Row)
   is
      XS : constant UInt16 := UInt16 (Natural (X1) + X_Offset);
      XE : constant UInt16 := UInt16 (Natural (X2) + X_Offset);
      YS : constant UInt16 := UInt16 (Natural (Y1) + Y_Offset);
      YE : constant UInt16 := UInt16 (Natural (Y2) + Y_Offset);
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

      --  Frame memory contents are undefined after reset, so blank it before
      --  turning the panel on rather than showing a screen of noise.
      Clear;

      --  DISPON takes effect at the next V-sync (datasheet 10.1 note 4),
      --  which is at most one frame away.
      Delay_Milliseconds (10);
      Command (DISPON);
   end Initialize;

   procedure Clear is
   begin
      Set_Address_Window (Column'First, Column'Last, Row'First, Row'Last);
      Start_Command (RAMWR);
      for Y in Row loop
         Write_Data (Blank_Row);
      end loop;
      End_Command;
   end Clear;

   procedure Set_Pixel
      (X : Column;
       Y : Row;
       C : Color)
   is
      --  RGB565: red in the top five bits, then green, then blue, sent most
      --  significant byte first.
      P : constant UInt16 :=
         Shift_Left (UInt16 (C.R), 11) or
         Shift_Left (UInt16 (C.G), 5) or
                     UInt16 (C.B);
   begin
      Set_Address_Window (X, X, Y, Y);
      Command (RAMWR, (UInt8 (Shift_Right (P, 8)), UInt8 (P and 16#FF#)));
   end Set_Pixel;
end ST7735;

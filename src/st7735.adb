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

   --  Panel function commands, datasheet section 10.2
   FRMCTR1 : constant := 16#B1#;  --  Frame rate control, normal mode
   FRMCTR2 : constant := 16#B2#;  --  Frame rate control, idle mode
   FRMCTR3 : constant := 16#B3#;  --  Frame rate control, partial mode
   INVCTR  : constant := 16#B4#;  --  Display inversion control
   PWCTR1  : constant := 16#C0#;  --  Power control 1 (GVDD)
   PWCTR2  : constant := 16#C1#;  --  Power control 2 (VGH/VGL)
   PWCTR3  : constant := 16#C2#;  --  Power control 3, normal mode
   PWCTR4  : constant := 16#C3#;  --  Power control 4, idle mode
   PWCTR5  : constant := 16#C4#;  --  Power control 5, partial mode
   VMCTR1  : constant := 16#C5#;  --  VCOM control
   GMCTRP1 : constant := 16#E0#;  --  Positive gamma correction
   GMCTRN1 : constant := 16#E1#;  --  Negative gamma correction

   --  COLMOD parameter. 16 bit/pixel is IFPF = 101; datasheet 10.1.30 note 2
   --  asks for 55h, which sets the RGB interface format to match, when 16
   --  bit/pixel data is written to frame memory.
   COLMOD_16BPP : constant UInt8 := 16#55#;

   --  MADCTL D3, the RGB/BGR order bit: 1 selects BGR (datasheet 10.1.27).
   MADCTL_BGR : constant UInt8 := 2#0000_1000#;

   No_Data : constant UInt8_Array (1 .. 0) := (1 .. 0 => 0);

   procedure Start_Command (Cmd : UInt8);
   procedure Write_Data (Data : UInt8_Array);
   procedure End_Command;

   procedure Command
      (Cmd  : UInt8;
       Data : UInt8_Array := No_Data);

   procedure Set_Address_Window
      (X1, X2 : Column;
       Y1, Y2 : Row);

   --  RGB565: red in the top five bits, then green, then blue.
   function To_RGB565
      (C : Color)
      return UInt16
   is (Shift_Left (UInt16 (C.R), 11) or
       Shift_Left (UInt16 (C.G), 5) or
                   UInt16 (C.B));

   --  CS is held low for the whole of a command, from its opcode through the
   --  last byte of its data, so that Fill and Put_Pixels can stream many rows
   --  of pixels into one memory write.
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

      --  The ST7735R and ST7735S take the same commands, but their reset
      --  values for the panel registers are not guaranteed to match, and
      --  either may be bonded to glass that wants something else. These are
      --  the values the common 1.8" modules are tuned for: about 60 Hz,
      --  column inversion, and the module vendors' power and gamma settings.
      Command (FRMCTR1, (16#01#, 16#2C#, 16#2D#));
      Command (FRMCTR2, (16#01#, 16#2C#, 16#2D#));
      Command (FRMCTR3, (16#01#, 16#2C#, 16#2D#, 16#01#, 16#2C#, 16#2D#));
      Command (INVCTR,  (1 => 16#07#));
      Command (PWCTR1,  (16#A2#, 16#02#, 16#84#));
      Command (PWCTR2,  (1 => 16#C5#));
      Command (PWCTR3,  (16#0A#, 16#00#));
      Command (PWCTR4,  (16#8A#, 16#2A#));
      Command (PWCTR5,  (16#8A#, 16#EE#));
      Command (VMCTR1,  (1 => 16#0E#));
      Command (GMCTRP1,
         (16#02#, 16#1C#, 16#07#, 16#12#, 16#37#, 16#32#, 16#29#, 16#2D#,
          16#29#, 16#25#, 16#2B#, 16#39#, 16#00#, 16#01#, 16#03#, 16#10#));
      Command (GMCTRN1,
         (16#03#, 16#1D#, 16#07#, 16#06#, 16#2E#, 16#2C#, 16#29#, 16#2D#,
          16#2E#, 16#2E#, 16#37#, 16#3F#, 16#00#, 16#00#, 16#02#, 16#10#));

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
      Fill (Column'First, Column'Last, Row'First, Row'Last, (0, 0, 0));
   end Clear;

   procedure Fill
      (X1, X2 : Column;
       Y1, Y2 : Row;
       C      : Color)
   is
      P        : constant UInt16 := To_RGB565 (C);
      Len      : constant Natural := (Natural (X2) - Natural (X1) + 1) * 2;
      Row_Data : UInt8_Array (0 .. Len - 1);
   begin
      for I in 0 .. Len / 2 - 1 loop
         Row_Data (I * 2)     := UInt8 (Shift_Right (P, 8));
         Row_Data (I * 2 + 1) := UInt8 (P and 16#FF#);
      end loop;

      Set_Address_Window (X1, X2, Y1, Y2);
      Start_Command (RAMWR);
      for Y in Y1 .. Y2 loop
         Write_Data (Row_Data);
      end loop;
      End_Command;
   end Fill;

   procedure Start_Pixels
      (X1, X2 : Column;
       Y1, Y2 : Row)
   is
   begin
      Set_Address_Window (X1, X2, Y1, Y2);
      Start_Command (RAMWR);
   end Start_Pixels;

   procedure Put_Pixels
      (Colors : Color_Array)
   is
      Data : UInt8_Array (0 .. Colors'Length * 2 - 1);
      I    : Natural := 0;
      P    : UInt16;
   begin
      for C of Colors loop
         P := To_RGB565 (C);
         Data (I)     := UInt8 (Shift_Right (P, 8));
         Data (I + 1) := UInt8 (P and 16#FF#);
         I := I + 2;
      end loop;
      if Data'Length > 0 then
         Write_Data (Data);
      end if;
   end Put_Pixels;

   procedure End_Pixels is
   begin
      End_Command;
   end End_Pixels;

   procedure Set_Pixel
      (X : Column;
       Y : Row;
       C : Color)
   is
      --  Sent most significant byte first.
      P : constant UInt16 := To_RGB565 (C);
   begin
      Set_Address_Window (X, X, Y, Y);
      Command (RAMWR, (UInt8 (Shift_Right (P, 8)), UInt8 (P and 16#FF#)));
   end Set_Pixel;
end ST7735;

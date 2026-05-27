--  Image read + write.
--
--  CCV supports PNG, JPG, and BMP for self-describing files.
--  PNG / JPG require libpng / libjpeg at link time; BMP works
--  without external libraries (CCV ships a built-in BMP reader).
--
--  Returns from Read / Write are CCV's status codes — Final
--  (0) on success, Error (non-zero) otherwise. Idiomatic Ada
--  callers should check the result.

with Interfaces.C; use Interfaces.C;

package Ccv.Io is

   --  File-format type flags (CCV_IO_*).
   --  These pick the input/output decoding strategy.

   type File_Type is new int;
   Any_File    : constant File_Type := 16#020#;  --  detect from header
   Bmp_File    : constant File_Type := 16#021#;
   Jpeg_File   : constant File_Type := 16#022#;
   Png_File    : constant File_Type := 16#023#;
   Binary_File : constant File_Type := 16#024#;

   --  Color-conversion modifier (CCV_IO_GRAY / CCV_IO_RGB_COLOR).
   --  CCV's reader REQUIRES one of these modifier bits to be set
   --  alongside the File_Type — without it, the read produces a
   --  null matrix and the caller crashes on use.
   type Color_Mode is new int;
   As_Gray  : constant Color_Mode := 16#100#;
   As_Color : constant Color_Mode := 16#300#;

   --  Result type. CCV_IO_FINAL is zero on success.
   type Read_Result is new int;
   Final         : constant Read_Result := 0;  -- success
   Continue      : constant Read_Result := 1;  -- partial / streaming
   Error_Result  : constant Read_Result := 2;
   Attempted     : constant Read_Result := 3;
   Unknown_Type  : constant Read_Result := 4;

   --  Read a file at Path into M. If M is Null_Matrix on entry,
   --  CCV allocates; otherwise it reuses M (allocations follow
   --  CCV's standard memory-pool rules). Returns Final on success.
   --
   --  The Mode parameter is REQUIRED in practice — CCV's read
   --  silently produces a null matrix if no color mode is set.
   --  Default is As_Color (3-channel output).
   function Read
     (Path : String;
      M    : in out Matrix;
      Ft   : File_Type := Any_File;
      Mode : Color_Mode := As_Color) return Read_Result;

   --  Write M to Path. Format inferred from Ft (Png_File / Jpeg_File
   --  / Bmp_File). Returns Final on success.
   function Write
     (M    : Matrix;
      Path : String;
      Ft   : File_Type := Png_File) return Read_Result;

end Ccv.Io;

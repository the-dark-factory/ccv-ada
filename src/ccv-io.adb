with Interfaces.C.Strings;
with System;

with Ccv.C;

package body Ccv.Io is

   ------------------------
   --  Read
   ------------------------

   function Read
     (Path : String;
      M    : in out Matrix;
      Ft   : File_Type := Any_File;
      Mode : Color_Mode := As_Color) return Read_Result
   is
      use Interfaces.C.Strings;
      C_Path  : chars_ptr := New_String (Path);
      Scratch : aliased System.Address := System.Address (M);
      Rc      : int;
   begin
      Rc := Ccv.C.ccv_read_impl
        (In_Ptr   => C_Path,
         X        => Scratch'Access,
         Cv_Type  => int (Ft) + int (Mode),  -- bitwise OR safe: non-overlapping bits
         Rows     => 0,
         Cols     => 0,
         Scanline => 0);
      M := Matrix (Scratch);
      Free (C_Path);
      return Read_Result (Rc);
   end Read;

   ------------------------
   --  Write
   ------------------------

   function Write
     (M    : Matrix;
      Path : String;
      Ft   : File_Type := Png_File) return Read_Result
   is
      use Interfaces.C.Strings;
      C_Path  : chars_ptr := New_String (Path);
      Len     : aliased size_t := 0;
      Rc      : int;
   begin
      Rc := Ccv.C.ccv_write
        (Mat     => System.Address (M),
         Out_Ptr => C_Path,
         Len     => Len'Access,
         Cv_Type => int (Ft),
         Conf    => System.Null_Address);
      Free (C_Path);
      return Read_Result (Rc);
   end Write;

end Ccv.Io;

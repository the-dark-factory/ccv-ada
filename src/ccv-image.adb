with System;

with Ccv.C;

package body Ccv.Image is

   ------------------------
   --  Color_Transform
   ------------------------

   procedure Color_Transform
     (Source : Matrix;
      Result : in out Matrix;
      Flag   : Color_Flag := Rgb_To_Yuv)
   is
      Scratch : aliased System.Address := System.Address (Result);
   begin
      Ccv.C.ccv_color_transform
        (A       => System.Address (Source),
         B       => Scratch'Access,
         Cv_Type => 0,
         Flag    => int (Flag));
      Result := Matrix (Scratch);
   end Color_Transform;

   ------------------------
   --  Flip
   ------------------------

   procedure Flip
     (Source    : Matrix;
      Result    : in out Matrix;
      Direction : Flip_Direction := Flip_X)
   is
      Scratch : aliased System.Address := System.Address (Result);
   begin
      Ccv.C.ccv_flip
        (A       => System.Address (Source),
         B       => Scratch'Access,
         Btype   => 0,
         Cv_Type => int (Direction));
      Result := Matrix (Scratch);
   end Flip;

   ------------------------
   --  Resample
   ------------------------

   procedure Resample
     (Source     : Matrix;
      Result     : in out Matrix;
      Rows_Scale : double;
      Cols_Scale : double;
      Method     : Resample_Method := Inter_Area)
   is
      Scratch : aliased System.Address := System.Address (Result);
   begin
      Ccv.C.ccv_resample
        (A          => System.Address (Source),
         B          => Scratch'Access,
         Btype      => 0,
         Rows_Scale => Rows_Scale,
         Cols_Scale => Cols_Scale,
         Cv_Type    => int (Method));
      Result := Matrix (Scratch);
   end Resample;

end Ccv.Image;

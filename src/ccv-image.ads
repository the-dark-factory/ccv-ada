--  Basic image processing — color space transforms, flip,
--  resample.
--
--  CCV's output-matrix idiom: every "produce a new image" call
--  takes the output as an in-out Matrix parameter. Pass
--  Null_Matrix on first call to allocate; CCV's internal cache
--  may reuse an existing matrix on subsequent calls with the
--  same input.

with Interfaces.C; use Interfaces.C;

package Ccv.Image is

   --  Color-transform direction flags.
   --  CCV currently exposes a single direction in the public
   --  ccv_color_transform API — RGB → YUV. To produce grayscale,
   --  callers typically use ccv_read with the CCV_IO_GRAY flag
   --  or call ccv_saturation / ccv_decolorize (separate APIs
   --  bound in later v0.x).
   type Color_Flag is new int;
   Rgb_To_Yuv : constant Color_Flag := 16#01#;

   --  Apply a color-space transform. Source stays untouched;
   --  Result is allocated or reused per CCV's matrix pool rules.
   procedure Color_Transform
     (Source : Matrix;
      Result : in out Matrix;
      Flag   : Color_Flag := Rgb_To_Yuv);

   --  Flip directions.
   type Flip_Direction is new int;
   Flip_X : constant Flip_Direction := 16#01#;  --  horizontal flip
   Flip_Y : constant Flip_Direction := 16#02#;  --  vertical flip
   Flip_Xy : constant Flip_Direction := 16#03#;  --  both

   --  Flip Source in the given direction, writing to Result.
   procedure Flip
     (Source    : Matrix;
      Result    : in out Matrix;
      Direction : Flip_Direction := Flip_X);

   --  Resampling algorithm.
   type Resample_Method is new int;
   Inter_Area   : constant Resample_Method := 16#01#;  --  best for downscale
   Inter_Linear : constant Resample_Method := 16#02#;
   Inter_Cubic  : constant Resample_Method := 16#03#;

   --  Scale Source by Rows_Scale × Cols_Scale (1.0 = same size).
   --  Result is allocated/reused per the matrix-pool rules.
   procedure Resample
     (Source     : Matrix;
      Result     : in out Matrix;
      Rows_Scale : double;
      Cols_Scale : double;
      Method     : Resample_Method := Inter_Area);

end Ccv.Image;

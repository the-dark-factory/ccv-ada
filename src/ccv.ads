--  Ada bindings to Liu Liu's CCV (C-based Computer Vision Library).
--
--  This is the root package. It defines the opaque Matrix type
--  that's threaded through every CCV operation, and exposes the
--  cache lifecycle calls. Typical usage:
--
--    Ccv.Enable_Default_Cache;
--    declare
--       Img : Ccv.Matrix := Ccv.Io.Read ("photo.png", Ccv.Io.Any_File);
--       Gray : Ccv.Matrix := Ccv.Null_Matrix;
--    begin
--       Ccv.Image.Color_Transform (Img, Gray, Ccv.Image.Rgb_To_Gray);
--       Ccv.Io.Write (Gray, "photo-gray.png", Ccv.Io.Png_File);
--       Ccv.Matrix_Free (Img);
--       Ccv.Matrix_Free (Gray);
--    end;
--    Ccv.Drain_Cache;
--
--  The C-binding surface lives in the private child Ccv.C;
--  public packages call into it. User code should not need it
--  directly.

with System;

package Ccv is

   --  Opaque handle to a CCV dense matrix (ccv_dense_matrix_t*).
   --  CCV uses these for everything — images, intermediate buffers,
   --  feature maps. Allocate via Read; release via Matrix_Free.
   type Matrix is private;

   --  Sentinel "no matrix yet" — pass as the out-parameter target
   --  for CCV functions that allocate on first call.
   Null_Matrix : constant Matrix;

   --  Enable CCV's internal LRU cache. The cache stores derived
   --  matrices (e.g. resamples, color transforms) so repeating an
   --  operation returns the cached result. Call once at startup.
   procedure Enable_Default_Cache;

   --  Flush CCV's internal cache. Call at shutdown to release
   --  cached matrices, or whenever you want a clean slate.
   procedure Drain_Cache;

   --  Free a matrix allocated by CCV (Read, Color_Transform,
   --  Resample, etc.). Calling Matrix_Free on Null_Matrix is a
   --  no-op. Calling it on the same matrix twice is undefined —
   --  zero the Ada Matrix variable after Free.
   procedure Matrix_Free (M : in out Matrix);

private

   --  Matrix is just an opaque pointer at the C level. We
   --  represent it as System.Address so it can be passed around
   --  without copying.
   type Matrix is new System.Address;

   Null_Matrix : constant Matrix := Matrix (System.Null_Address);

end Ccv;

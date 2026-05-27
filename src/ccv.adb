with System; use type System.Address;

with Ccv.C;

package body Ccv is

   ------------------------
   --  Enable_Default_Cache
   ------------------------

   procedure Enable_Default_Cache is
   begin
      Ccv.C.ccv_enable_default_cache;
   end Enable_Default_Cache;

   ------------------------
   --  Drain_Cache
   ------------------------

   procedure Drain_Cache is
   begin
      Ccv.C.ccv_drain_cache;
   end Drain_Cache;

   ------------------------
   --  Matrix_Free
   ------------------------

   procedure Matrix_Free (M : in out Matrix) is
   begin
      if System.Address (M) /= System.Null_Address then
         Ccv.C.ccv_matrix_free (System.Address (M));
         M := Null_Matrix;
      end if;
   end Matrix_Free;

end Ccv;

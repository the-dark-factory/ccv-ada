--  Thin Ada bindings to CCV's extern "C" surface.
--
--  INTERNAL — public Ccv packages call into this. User code
--  shouldn't need it directly.
--
--  Naming preserves CCV's `ccv_` prefix so a grep against ccv.h
--  cross-references cleanly. Public Ada packages adapt to idiom.
--
--  Pinned to CCV upstream HEAD as of 2026-05-27 (commit "Fix a
--  loading issue" — Liu Liu's unstable-branch latest). When CCV
--  is re-vendored, audit this file for API changes.

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with System;

package Ccv.C is

   subtype Chars_Ptr is Interfaces.C.Strings.chars_ptr;

   --  ccv_dense_matrix_t** — pointer-to-pointer, the CCV idiom
   --  for in/out matrix parameters (NULL on input = allocate;
   --  non-NULL = reuse). We represent as access to System.Address.
   type Matrix_Out is access all System.Address
     with Convention => C;

   ---------------
   --  Cache lifecycle
   ---------------

   procedure ccv_enable_default_cache
     with Import, Convention => C, External_Name => "ccv_enable_default_cache";

   procedure ccv_drain_cache
     with Import, Convention => C, External_Name => "ccv_drain_cache";

   procedure ccv_matrix_free (Mat : System.Address)
     with Import, Convention => C, External_Name => "ccv_matrix_free";

   ---------------
   --  Image I/O
   ---------------

   --  Read from path: `in` is a const char* file path, `x` is the
   --  output matrix double-pointer. rows/cols/scanline are for
   --  raw-data reads (CCV_IO_*_RAW types); for self-describing
   --  formats (PNG/JPG/BMP) they're 0.
   function ccv_read_impl
     (In_Ptr   : Chars_Ptr;
      X        : access System.Address;
      Cv_Type  : int;
      Rows     : int;
      Cols     : int;
      Scanline : int) return int
     with Import, Convention => C, External_Name => "ccv_read_impl";

   --  Write matrix to path. `out` is destination file path
   --  (writable char*); `len` is in-out byte count; conf is
   --  format-specific config (pass NULL for defaults).
   function ccv_write
     (Mat     : System.Address;
      Out_Ptr : Chars_Ptr;
      Len     : access size_t;
      Cv_Type : int;
      Conf    : System.Address) return int
     with Import, Convention => C, External_Name => "ccv_write";

   ---------------
   --  Image processing
   ---------------

   --  Color-space transform. `flag` selects direction (e.g.
   --  CCV_RGB_TO_YUV = 0x01).
   procedure ccv_color_transform
     (A       : System.Address;
      B       : access System.Address;
      Cv_Type : int;
      Flag    : int)
     with Import, Convention => C, External_Name => "ccv_color_transform";

   --  Geometric flip. btype = output type bits (0 = same as input
   --  type), type = direction (CCV_FLIP_X | CCV_FLIP_Y).
   procedure ccv_flip
     (A     : System.Address;
      B     : access System.Address;
      Btype : int;
      Cv_Type : int)
     with Import, Convention => C, External_Name => "ccv_flip";

   --  Resample. rows_scale and cols_scale are doubles (e.g. 0.5
   --  to halve, 2.0 to double). type selects algorithm
   --  (CCV_INTER_AREA / CCV_INTER_LINEAR / CCV_INTER_CUBIC).
   procedure ccv_resample
     (A          : System.Address;
      B          : access System.Address;
      Btype      : int;
      Rows_Scale : double;
      Cols_Scale : double;
      Cv_Type    : int)
     with Import, Convention => C, External_Name => "ccv_resample";

end Ccv.C;

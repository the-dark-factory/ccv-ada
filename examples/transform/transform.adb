--  Smoke test for ada-ccv: load a PNG, flip it horizontally,
--  write the result. Exercises the load → process → save path
--  end-to-end. If this runs to completion and the output PNG
--  exists with reasonable bytes, the binding is alive.

with Ada.Text_IO;       use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Directories;

with Ccv;
with Ccv.Io;     use type Ccv.Io.Read_Result;
with Ccv.Image;

procedure Transform is
   --  PNG read requires the upstream CCV to have been built with
   --  libpng support (configure must detect /opt/homebrew/include/
   --  png.h via pkg-config or CPPFLAGS). See CHARTER's build notes.
   Input_Path  : constant String := "fixtures/book.png";
   Output_Path : constant String := "book-flipped.png";
   Source : Ccv.Matrix := Ccv.Null_Matrix;
   Result : Ccv.Matrix := Ccv.Null_Matrix;
   Status : Ccv.Io.Read_Result;
begin
   Put_Line ("ada-ccv smoke test");
   Put_Line ("------------------");

   if not Ada.Directories.Exists (Input_Path) then
      Put_Line ("ERROR: fixture missing — expected " & Input_Path);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   Ccv.Enable_Default_Cache;

   Put ("Reading " & Input_Path & " ... ");
   Status := Ccv.Io.Read (Input_Path, Source);
   if Status /= Ccv.Io.Final then
      Put_Line ("FAILED (status =" & Status'Image & ")");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;
   Put_Line ("ok");

   Put ("Flipping horizontally ... ");
   Ccv.Image.Flip (Source, Result, Ccv.Image.Flip_X);
   Put_Line ("ok");

   Put ("Writing " & Output_Path & " ... ");
   Status := Ccv.Io.Write (Result, Output_Path, Ccv.Io.Png_File);
   if Status /= Ccv.Io.Final then
      Put_Line ("FAILED (status =" & Status'Image & ")");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Put_Line ("ok");
   end if;

   --  Cleanup. CCV's cache may have retained references to these
   --  matrices; Drain_Cache before exit returns everything to the
   --  allocator.
   Ccv.Matrix_Free (Source);
   Ccv.Matrix_Free (Result);
   Ccv.Drain_Cache;

   Put_Line ("done — output at " & Output_Path);
end Transform;

package body Ada.Interrupts is

   procedure Attach_Handler
     (New_Handler : Parameterless_Handler;
      Interrupt   : Interrupt_ID)
   is
   begin
      raise Program_Error;
   end Attach_Handler;

   function Current_Handler
     (Interrupt : Interrupt_ID) return Parameterless_Handler
   is
   begin
      raise Program_Error;
      return null;
   end Current_Handler;

   procedure Detach_Handler (Interrupt : Interrupt_ID) is
   begin
      raise Program_Error;
   end Detach_Handler;

   procedure Exchange_Handler
     (Old_Handler : out Parameterless_Handler;
      New_Handler : Parameterless_Handler;
      Interrupt   : Interrupt_ID)
   is
   begin
      raise Program_Error;
   end Exchange_Handler;

   function Get_CPU
     (Interrupt : Interrupt_ID) return System.Multiprocessors.CPU_Range
   is
   begin
      raise Program_Error;
      return System.Multiprocessors.Not_A_Specific_CPU;
   end Get_CPU;

   function Is_Attached (Interrupt : Interrupt_ID) return Boolean is
   begin
      raise Program_Error;
      return False;
   end Is_Attached;

   function Is_Reserved (Interrupt : Interrupt_ID) return Boolean is
   begin
      raise Program_Error;
      return False;
   end Is_Reserved;

   function Reference (Interrupt : Interrupt_ID) return System.Address is
   begin
      raise Program_Error;
      return System.Null_Address;
   end Reference;

end Ada.Interrupts;

with Interfaces.C;
with System.Address_To_Access_Conversions;

package body System.Interrupts is

   use type Interfaces.C.int;

   type User_Handler_Array is array (Interrupt_ID) of Parameterless_Handler;
   type Arg_Array is array (Interrupt_ID) of aliased Interfaces.C.int;

   User_Handlers : User_Handler_Array := (others => null);
   Source_Args   : Arg_Array;

   GPIO_Intr_Source  : constant Interrupt_ID := 16;
   GPIO_Intr_Source2 : constant Interrupt_ID := 18;

   function Gnat_Esp_Intr_Alloc
     (Source : Interfaces.C.int;
      Flags  : Interfaces.C.int;
      Hnd    : System.Address;
      Arg    : System.Address;
      Handle : access System.Address) return Interfaces.C.int
   with Import, Convention => C, External_Name => "__gnat_esp_intr_alloc";

   procedure Gnat_GPIO_Clear_Intr_Status_For_Core (Core : Interfaces.C.int)
   with
     Import,
     Convention    => C,
     External_Name => "__gnat_gpio_clear_intr_status_for_core";

   procedure Interrupt_Trampoline (Arg : System.Address)
   with Convention => C;

   procedure Install_Handler (Interrupt : Interrupt_ID);

   procedure Interrupt_Trampoline (Arg : System.Address) is
      package Conv is new
        System.Address_To_Access_Conversions (Interfaces.C.int);

      Source_Access : constant Conv.Object_Pointer := Conv.To_Pointer (Arg);
      Source_Id     : constant Interrupt_ID :=
        Interrupt_ID (Source_Access.all);
      Handler       : constant Parameterless_Handler :=
        User_Handlers (Source_Id);
   begin
      if Source_Id = GPIO_Intr_Source then
         Gnat_GPIO_Clear_Intr_Status_For_Core (0);

      elsif Source_Id = GPIO_Intr_Source2 then
         Gnat_GPIO_Clear_Intr_Status_For_Core (1);
      end if;

      if Handler /= null then
         Handler.all;
      end if;
   end Interrupt_Trampoline;

   procedure Install_Handler (Interrupt : Interrupt_ID) is
      Result : Interfaces.C.int;
      Handle : aliased System.Address := System.Null_Address;
   begin
      Result :=
        Gnat_Esp_Intr_Alloc
          (Source => Interfaces.C.int (Interrupt),
           Flags  => 0,
           Hnd    => Interrupt_Trampoline'Address,
           Arg    => Source_Args (Interrupt)'Address,
           Handle => Handle'Access);

      if Result /= 0 then
         raise Program_Error
           with
             "esp_intr_alloc failed, esp_err_t="
             & Interfaces.C.int'Image (Result);
      end if;
   end Install_Handler;

   procedure Install_Restricted_Handlers
     (Prio : Interrupt_Priority; Handlers : Handler_Array)
   is
      pragma Unreferenced (Prio);
   begin
      for J in Handlers'Range loop
         User_Handlers (Handlers (J).Interrupt) := Handlers (J).Handler;
         Install_Handler (Handlers (J).Interrupt);
      end loop;
   end Install_Restricted_Handlers;

   procedure Install_Restricted_Handlers_Sequential is
   begin
      null;
   end Install_Restricted_Handlers_Sequential;

begin
   for I in Interrupt_ID'Range loop
      Source_Args (I) := Interfaces.C.int (I);
   end loop;
end System.Interrupts;

with System.Interrupts;
with System.Multiprocessors;
with Ada.Task_Identification;

package Ada.Interrupts is

   type Interrupt_ID is new System.Interrupts.Ada_Interrupt_ID;

   type Parameterless_Handler is access protected procedure;

   function Is_Reserved (Interrupt : Interrupt_ID) return Boolean with
     SPARK_Mode,
     Volatile_Function,
     Global => Ada.Task_Identification.Tasking_State;

   function Is_Attached (Interrupt : Interrupt_ID) return Boolean with
     SPARK_Mode,
     Volatile_Function,
     Global => Ada.Task_Identification.Tasking_State;

   function Current_Handler
     (Interrupt : Interrupt_ID) return Parameterless_Handler
   with
     SPARK_Mode => Off,
     Global     => null;

   procedure Attach_Handler
     (New_Handler : Parameterless_Handler;
      Interrupt   : Interrupt_ID)
   with
     SPARK_Mode => Off,
     Global     => null;

   procedure Exchange_Handler
     (Old_Handler : out Parameterless_Handler;
      New_Handler : Parameterless_Handler;
      Interrupt   : Interrupt_ID)
   with
     SPARK_Mode => Off,
     Global     => null;

   procedure Detach_Handler (Interrupt : Interrupt_ID) with
     SPARK_Mode,
     Global => (In_Out => Ada.Task_Identification.Tasking_State);

   function Reference (Interrupt : Interrupt_ID) return System.Address with
     SPARK_Mode => Off,
     Global     => null;

   function Get_CPU
     (Interrupt : Interrupt_ID) return System.Multiprocessors.CPU_Range
   with
     SPARK_Mode,
     Volatile_Function,
     Global => Ada.Task_Identification.Tasking_State;

private
   pragma Inline (Is_Reserved);
   pragma Inline (Is_Attached);
   pragma Inline (Current_Handler);
   pragma Inline (Attach_Handler);
   pragma Inline (Detach_Handler);
   pragma Inline (Exchange_Handler);
   pragma Inline (Get_CPU);
end Ada.Interrupts;
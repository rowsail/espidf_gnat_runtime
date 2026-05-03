package System.Interrupts is
   pragma Elaborate_Body;

   Default_Interrupt_Priority : constant System.Interrupt_Priority :=
     System.Interrupt_Priority'Last;

   type Ada_Interrupt_ID is range 0 .. 255;
   type Interrupt_ID is range 0 .. 255;

   subtype System_Interrupt_Id is Interrupt_ID;

   type Parameterless_Handler is access protected procedure;

   type Handler_Index is range 0 .. Integer'Last;

   type Handler_Item is record
      Interrupt : Interrupt_ID;
      Handler   : Parameterless_Handler;
   end record;

   type Handler_Array is array (Handler_Index range <>) of Handler_Item;

   procedure Install_Restricted_Handlers
     (Prio     : Interrupt_Priority;
      Handlers : Handler_Array);

   procedure Install_Restricted_Handlers_Sequential;
   pragma Export
     (C, Install_Restricted_Handlers_Sequential, "__gnat_attach_all_handlers");
end System.Interrupts;
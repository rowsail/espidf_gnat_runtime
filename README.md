[![ACATS](https://github.com/godunko/espidf_gnat_runtime/actions/workflows/acats.yaml/badge.svg)](https://github.com/godunko/espidf_gnat_runtime/actions/workflows/acats.yaml)

# ESP-IDF GNAT Runtime — Interrupt Support Fork

This repository is a fork of
[godunko/espidf_gnat_runtime](https://github.com/godunko/espidf_gnat_runtime).
It extends the upstream runtime with full interrupt-handler support for the
ESP32 family: Ada ceiling priorities are wired through to the ESP-IDF interrupt
allocator, all peripheral sources are validated before allocation, and the
GPIO status-register housekeeping required before dispatching an Ada handler is
handled automatically by the runtime.

For general information about the runtime (key features, supported
architectures, prerequisites, and getting started) refer to the upstream README
at [godunko/espidf_gnat_runtime](https://github.com/godunko/espidf_gnat_runtime).

---

## Changes from upstream

All changes are confined to two files:

| File | Role |
|------|------|
| `source/s-interr.adb` | Ada runtime body — handler registration and dispatch |
| `source/freertos.c` | C glue — ESP-IDF calls, GPIO HAL, source-ID validation |

### 1 — Priority wired through to `esp_intr_alloc`

The upstream runtime called `esp_intr_alloc` with a hard-coded
`ESP_INTR_FLAG_LEVEL1` flag, ignoring the Ada ceiling priority declared in the
protected object entirely.

This fork replaces the call to `__gnat_esp_intr_alloc` with a new helper,
`__gnat_esp_intr_alloc_c_handler`, that accepts the Ada `Interrupt_Priority`
value and maps it to the correct ESP-IDF level flag:

```c
// source/freertos.c
int __gnat_esp_intr_alloc_c_handler(
    int source, int ada_interrupt_priority,
    intr_handler_t handler, void *arg, intr_handle_t *ret_handle)
{
    // Ada Interrupt_Priority 241..255 maps to ESP-IDF C-callable levels 1..3.
    // 241..245 → LEVEL1, 246..250 → LEVEL2, 251..255 → LEVEL3.
    int flags = ESP_INTR_FLAG_LEVEL1
                + ((clamped - 241) * 3) / 15;
    return esp_intr_alloc(source, flags, handler, arg, ret_handle);
}
```

The Xtensa core has seven hardware interrupt levels.  Levels 4, 5, and NMI
require hand-written assembly entry points and cannot invoke C (or Ada)
functions.  The mapping deliberately caps at level 3, so
`Interrupt_Priority'Last` (255) selects the highest level at which an Ada
handler can safely execute.

The Ada `Interrupt_Priority` range is 241–255 (defined in `system.ads`).
The full mapping is:

| Ada `Interrupt_Priority` | ESP-IDF flag | Xtensa hardware level |
|--------------------------|--------------|----------------------|
| 241–245 | `ESP_INTR_FLAG_LEVEL1` | 1 (lowest C-callable) |
| 246–250 | `ESP_INTR_FLAG_LEVEL2` | 2 |
| 251–255 | `ESP_INTR_FLAG_LEVEL3` | 3 (highest C-callable) |

`Install_Restricted_Handlers` in `s-interr.adb` previously had
`pragma Unreferenced (Prio)`.  The priority is now threaded through
`Install_Handler` to the C helper so the hardware level reflects the Ada
ceiling priority declared in each protected object.

### 2 — Source-ID validation before allocation

Before calling `esp_intr_alloc`, `Install_Handler` now calls
`__gnat_is_valid_intr_source`:

```c
// source/freertos.c
int __gnat_is_valid_intr_source(int source)
{
    // Reserved slots in esp_isr_names[] are NULL; valid slots have a name.
    return source >= 0
           && source < ETS_MAX_INTR_SOURCE
           && esp_isr_names[source] != NULL;
}
```

`esp_isr_names[]` is an ESP-IDF-internal table that maps each source index to a
human-readable name string.  Reserved or unassigned slots hold `NULL`.  This
approach is chip-portable: the same C code correctly rejects reserved IDs on
any ESP32 variant without needing chip-specific Ada knowledge.

If the check fails, `Install_Handler` raises `Program_Error` with the offending
source ID before any IDF call is made, rather than producing undefined behaviour
deep inside the interrupt matrix.

### 3 — Target-portable GPIO source IDs

The upstream runtime hard-coded the GPIO interrupt source IDs (16 and 18 on the
ESP32-S3).  These values differ across ESP32 variants.

This fork exports them from C using the `soc/interrupts.h` enum, so the Ada
runtime always gets the correct value for the chip being compiled for:

```c
// source/freertos.c
const int __gnat_gpio_intr_source_core0 = ETS_GPIO_INTR_SOURCE;
#ifdef ETS_GPIO_INTR_SOURCE2
const int __gnat_gpio_intr_source_core1 = ETS_GPIO_INTR_SOURCE2;
#else
const int __gnat_gpio_intr_source_core1 = -1;  // single-core: not present
#endif
```

`s-interr.adb` imports these as `Interfaces.C.int` variables and uses them at
elaboration time.  The sentinel value `-1` for single-core chips is checked
explicitly in `Interrupt_Trampoline` before clearing Core-1 GPIO status.

### 4 — GPIO status-register housekeeping in the trampoline

`Interrupt_Trampoline` is the C-convention function registered with
`esp_intr_alloc` for every Ada handler.  It looks up the Ada procedure pointer
in the `User_Handlers` table and calls it.

GPIO is the only peripheral whose interrupt-status register the runtime must
clear *before* dispatching the Ada handler.  Every other peripheral is expected
to clear its own status register inside its own handler; GPIO is the exception
because a single status register covers all pins simultaneously and must be
cleared before the handler re-enables interrupts (otherwise the same edge
re-fires immediately).

The trampoline now calls `__gnat_gpio_clear_intr_status_for_core` before
invoking the Ada procedure when the source ID matches the GPIO core-0 or
core-1 source:

```c
// source/freertos.c
void __gnat_gpio_clear_intr_status_for_core(int core)
{
    gpio_dev_t *dev = GPIO_LL_GET_HW(0);
    uint32_t low = 0, high = 0;
    gpio_ll_get_intr_status(dev, core, &low);
    gpio_ll_get_intr_status_high(dev, core, &high);
    if (low)  gpio_ll_clear_intr_status(dev, low);
    if (high) gpio_ll_clear_intr_status_high(dev, high);
}
```

The HAL functions (`hal/gpio_ll.h`) are used rather than direct register
writes so that the code remains correct across ESP32 variants that have
different register layouts.

---

## Related repositories

* [godunko/espidf_gnat_runtime](https://github.com/godunko/espidf_gnat_runtime) — upstream runtime this fork is based on
* [rowsail/esp32s3_template](https://github.com/rowsail/esp32s3_template) — application template that uses this fork
* [godunko/esp32s3_template](https://github.com/godunko/esp32s3_template) — upstream application template

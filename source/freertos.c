#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

#include <esp_intr_alloc.h>
#include <hal/gpio_ll.h>
#include <soc/gpio_periph.h>
#include <soc/interrupts.h>

TickType_t __gnat_pdMS_TO_TICKS(unsigned ms)
{
  return pdMS_TO_TICKS(ms);
}

unsigned __gnat_pdTICKS_TO_MS(TickType_t ticks)
{
  return pdTICKS_TO_MS(ticks);
}

SemaphoreHandle_t __gnat_xSemaphoreCreateBinary()
{
  return xSemaphoreCreateBinary();
}

SemaphoreHandle_t __gnat_xSemaphoreCreateMutex()
{
  return xSemaphoreCreateMutex();
}

SemaphoreHandle_t __gnat_xSemaphoreCreateRecursiveMutex()
{
  return xSemaphoreCreateRecursiveMutex();
}

void __gnat_vSemaphoreDelete(SemaphoreHandle_t xSemaphore)
{
  vSemaphoreDelete(xSemaphore);
}

BaseType_t __gnat_xSemaphoreGive(SemaphoreHandle_t xSemaphore)
{
  return xSemaphoreGive(xSemaphore);
}

BaseType_t __gnat_xSemaphoreGiveRecursive(SemaphoreHandle_t xSemaphore)
{
  return xSemaphoreGiveRecursive(xSemaphore);
}

BaseType_t __gnat_xSemaphoreTake(SemaphoreHandle_t xSemaphore, TickType_t xTicksToWait)
{
  return xSemaphoreTake(xSemaphore, xTicksToWait);
}

BaseType_t __gnat_xSemaphoreTakeRecursive(SemaphoreHandle_t xSemaphore, TickType_t xTicksToWait)
{
  return xSemaphoreTakeRecursive(xSemaphore, xTicksToWait);
}

BaseType_t __gnat_xTaskCreate(TaskFunction_t pvTaskCode, const char * const pcName, const configSTACK_DEPTH_TYPE uxStackDepth, void *pvParameters, UBaseType_t uxPriority, TaskHandle_t *pxCreatedTask)
{
  return xTaskCreate(pvTaskCode, pcName, uxStackDepth, pvParameters, uxPriority, pxCreatedTask);
}

int __gnat_esp_intr_alloc(int source, int flags, intr_handler_t handler, void *arg, intr_handle_t *ret_handle)
{
  return esp_intr_alloc(source, flags, handler, arg, ret_handle);
}

int __gnat_esp_intr_free(intr_handle_t handle)
{
  return esp_intr_free(handle);
}

int __gnat_is_valid_intr_source(int source)
{
  return source >= 0
         && source < ETS_MAX_INTR_SOURCE
         && esp_isr_names[source] != NULL;
}

/* GPIO interrupt source IDs for the current target chip.
 * Exporting these from C lets Ada avoid hardcoding values that differ
 * across ESP32 variants.  On single-core chips there is no second GPIO
 * source; -1 is used as a sentinel meaning "not present".
 */
const int __gnat_gpio_intr_source_core0 = ETS_GPIO_INTR_SOURCE;

#ifdef ETS_GPIO_INTR_SOURCE2
const int __gnat_gpio_intr_source_core1 = ETS_GPIO_INTR_SOURCE2;
#else
const int __gnat_gpio_intr_source_core1 = -1;
#endif

void __gnat_gpio_clear_intr_status_for_core(int core)
{
  gpio_dev_t *dev = GPIO_LL_GET_HW(0);
  uint32_t low = 0;
  uint32_t high = 0;

  gpio_ll_get_intr_status(dev, core, &low);
  gpio_ll_get_intr_status_high(dev, core, &high);

  if (low != 0) {
    gpio_ll_clear_intr_status(dev, low);
  }

  if (high != 0) {
    gpio_ll_clear_intr_status_high(dev, high);
  }
}

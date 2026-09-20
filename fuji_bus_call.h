#include <stdbool.h>
#include <stdint.h>

#define FUJI_DEVICEID_DISK              0x31

#define U32_MSW(v) ((uint16_t)(((uint32_t)(v) >> 16) & 0xFFFF))  // Most Significant Word
#define U32_LSW(v) ((uint16_t)((uint32_t)(v) & 0xFFFF))          // Least Significant Word
#define U16_MSB(w) ((uint8_t)(((uint16_t)(w) >> 8) & 0xFF))
#define U16_LSB(w) ((uint8_t)((uint16_t)(w) & 0xFF))

#define NATIVE_SPLIT_U16(w) U16_LSB(w), U16_MSB(w)
#define NATIVE_SPLIT_U32(l)                                             \
  U16_LSB(U32_LSW(l)), U16_MSB(U32_LSW(l)),                             \
    U16_LSB(U32_MSW(l)), U16_MSB(U32_MSW(l))

enum {
  FUJI_FIELD_NONE        = 0,
  FUJI_FIELD_A1          = 1,
  FUJI_FIELD_A1_A2       = 2,
  FUJI_FIELD_A1_A2_A3    = 3,
  FUJI_FIELD_A1_A2_A3_A4 = 4,
  FUJI_FIELD_B12         = 5,
  FUJI_FIELD_B12_B34     = 6,
  FUJI_FIELD_C1234       = 7,
  FUJI_FIELD_DATA        = 8,
  FUJI_FIELD_REPLY       = 16,
};

enum {
  DISKCMD_WRITE         = 0x57, // W
  DISKCMD_STATUS        = 0x53, // S
  DISKCMD_READ          = 0x52, // R
  DISKCMD_PUT           = 0x50, // P
  DISKCMD_PERCOM_WRITE  = 0x4F, // O
  DISKCMD_PERCOM_READ   = 0x4E, // N
  DISKCMD_HSIO_INDEX    = 0x3F, // ?
  DISKCMD_FORMAT_MEDIUM = 0x22, // "
  DISKCMD_FORMAT        = 0x21, // !
};

extern bool fuji_bus_call(uint8_t device, uint8_t fuji_cmd, uint8_t fields,
                          uint8_t aux1, uint8_t aux2, uint8_t aux3, uint8_t aux4,
                          const void *buf, size_t buf_length);

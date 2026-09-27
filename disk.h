#ifndef DISK_H
#define DISK_H

#include <stdint.h>

#define SECTOR_SIZE       128
#define SECTORS_PER_TRACK 26
#define TRACKS_PER_DISK   77
#define SUCCESS           0
#define DISK_ERROR        1

extern void bios_home(void);
extern void *bios_seldsk(uint8_t drive) __z88dk_fastcall;
extern void bios_settrk(uint16_t track) __z88dk_fastcall;
extern void bios_setsec(uint8_t sector) __z88dk_fastcall;
extern void bios_setdma(uint16_t dma_addr) __z88dk_fastcall;
extern uint8_t bios_read(void);
extern uint8_t bios_write(uint8_t write_type) __z88dk_fastcall;

#endif /* DISK_H */

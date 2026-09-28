/* Copyright (C) 2026 Chris Osborn <fozztexx@fozztexx.com>
/*
/* This program is free software: you can redistribute it and/or modify
/* it under the terms of the GNU General Public License as published by
/* the Free Software Foundation, either version 3 of the License, or
/* (at your option) any later version.
/*
/* This program is distributed in the hope that it will be useful,
/* but WITHOUT ANY WARRANTY; without even the implied warranty of
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
/* GNU General Public License for more details.
/*
/* You should have received a copy of the GNU General Public License
/* along with this program. If not, see <https://www.gnu.org/licenses/>.
*/

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
extern void bios_init(void);

#endif /* DISK_H */

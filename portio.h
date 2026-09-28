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

#include <stdint.h>

#define PORT_INIT() port_init(1, 16);
#define PORT_TICKS_PER_SECOND 1000

extern void port_init(uint8_t ctc_divisor, uint8_t sio_divisor) __z88dk_callee;

// return data if it arrives before timeout or -1 if timeout expires
extern int port_getc_timeout(uint16_t timeout) __z88dk_fastcall;

// reads and decodes SLIP into two buffers
// returns length of data received, if timeout expires returns all data received until then
// timeout resets when a character is received
extern uint16_t port_getbuf_slip_dual(void *hdr_buf, uint16_t hdr_len,
                                      void *data_buf, uint16_t data_len,
                                      uint16_t timeout) __z88dk_callee;

// writes character to port
extern void port_putc(uint8_t c) __z88dk_fastcall;

// writes data to port handling SLIP escapes, returns number of bytes written
extern uint16_t port_putbuf_slip(const void *buf, uint16_t len) __z88dk_callee;

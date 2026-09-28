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

#ifndef SPECIAL_H
#define SPECIAL_H

#include <stdint.h>

// Pickles & Trout special functions from chapter 16 of the User's Manual

enum {
  PT_FUNC_SERIAL_A_GETC             = 1,
  PT_FUNC_SERIAL_B_GETC             = 2,
  PT_FUNC_SERIAL_A_PUTC             = 3,
  PT_FUNC_SERIAL_B_PUTC             = 4,
  PT_FUNC_SERIAL_A_STATUS           = 5,
  PT_FUNC_SERIAL_B_STATUS           = 6,
  PT_FUNC_PRINTER_STATUS            = 7,
  PT_FUNC_PRINTER_PUTC              = 8,
  PT_FUNC_PRINTER_SET_OPT           = 9,
  PT_FUNC_PRINTER_SET_PAGE_LENGTH   = 10,
  PT_FUNC_PRINTER_SET_LINES         = 11,
  PT_FUNC_PRINTER_SET_TOP           = 12,
  PT_FUNC_SET_DRIVES_UKNOWN_DENSITY = 13,
  PT_FUNC_GET_REAL_TIME_CLOCK       = 14,
  PT_FUNC_GET_TIME_OF_DAY           = 15,
  PT_FUNC_SET_TIME_OF_DAY           = 16,
  PT_FUNC_GET_CURSOR_XY             = 17,
  PT_FUNC_GET_CHAR_AT_CURSOR        = 18,
  PT_FUNC_SET_CURSOR_SIZE           = 19,
  PT_FUNC_SET_CURSOR_BLINK          = 20,
  PT_FUNC_ENABLE_SCREEN_ACCESS      = 21,
  PT_FUNC_DISABLE_SCREEN_ACCESS     = 22,
  PT_FUNC_SET_SPLIT_SCREEN          = 23,
  PT_FUNC_GET_DATE                  = 24,
  PT_FUNC_SET_DATE                  = 25,
  PT_FUNC_SET_CONTROL_C_TRAP        = 26,
  PT_FUNC_SET_DRIVE_ACCESS_FLAG     = 27,
  PT_FUNC_SET_DRIVE_RW_FLAG         = 28,
  PT_FUNC_HARD_DRIVE_RESERVED       = 29,
  PT_FUNC_SERIAL_SEND_BREAK         = 30,
  PT_FUNC_ENABLE_TERMINAL_EMULATION = 31,
  PT_FUNC_INIT_FLASHING_MESSAGE     = 32,
  PT_FUNC_FLASH_MESSAGE             = 33,
  PT_FUNC_RESTORE_DISPLAY           = 34,
  PT_FUNC_GET_DISK_STATUS           = 35,
};

extern void pickles_trout_special(uint8_t func, uint8_t reg_C,
                                  uint8_t reg_D, uint8_t reg_E,
                                  uint8_t reg_H, uint8_t reg_L,
                                  uint8_t reg_A);
extern void pickles_trout_set_date(uint8_t day_of_week, uint8_t day_of_month,
                              uint8_t month, uint8_t year);
extern void pickles_trout_set_time(uint8_t seconds, uint8_t minutes, uint8_t hours);

#endif /* SPECIAL_H */

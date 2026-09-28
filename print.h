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

#ifndef PRINT_H
#define PRINT_H

#include <stdint.h>

extern void print_string(char *str) __z88dk_fastcall;
extern void print_char(char c) __z88dk_fastcall;

#define printChar(c) print_char(c)

extern void printHex(uint16_t val, uint16_t width, char leading);
extern void printHex32(uint32_t val, uint16_t width, char leading);
extern void printDec(uint16_t val, uint16_t width, char leading);
extern void dumpHex(void *ptr, uint16_t count, uint16_t address);
extern void printString(const char *str);

#ifdef __SCCZ80
//#warning "stdarg/vararg does not work on this compiler"
#else
#include <stdarg.h>
extern void vconsolef(const char *format, va_list args);
extern void consolef(const char *format, ...);
#endif /* __SCCZ80 */

#endif /* PRINT_H */

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

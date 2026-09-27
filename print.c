#include "print.h"
#include <ctype.h>

void printHex(uint16_t val, uint16_t width, char leading)
{
  uint16_t digits, tval;
  char c;


  for (tval = val, digits = 0; tval; tval >>= 4, digits++)
    ;
  if (!digits)
    digits = 1;

  for (; digits < width; width--)
    printChar(leading);

  while (digits) {
    digits--;
    c = (val >> 4 * digits) & 0xf;
    printChar('0' + c + (c > 9 ? 7 : 0));
  }

  return;
}

void printHex32(uint32_t val, uint16_t width, char leading)
{
  uint16_t digits;
  uint32_t tval;
  char c;


  for (tval = val, digits = 0; tval; tval >>= 4, digits++)
    ;
  if (!digits)
    digits = 1;

  for (; digits < width; width--)
    printChar(leading);

  while (digits) {
    digits--;
    c = (val >> 4 * digits) & 0xf;
    printChar('0' + c + (c > 9 ? 7 : 0));
  }

  return;
}

void printDec(uint16_t val, uint16_t width, char leading)
{
  uint16_t digits, tval, tens;


  for (tval = val, digits = 0; tval; tval /= 10, digits++)
    ;
  if (!digits)
    digits = 1;
  for (tval = digits - 1, tens = 1; tval; tval--, tens *= 10)
    ;

  for (; digits < width; width--)
    printChar(leading);

  while (digits) {
    digits--;
    printChar('0' + (val / tens) % 10);
    tens /= 10;
  }

  return;
}

void printDec32(uint32_t val, uint16_t width, char leading)
{
  uint32_t tval, tens;
  uint16_t digits;


  for (tval = val, digits = 0; tval; tval /= 10, digits++)
    ;
  if (!digits)
    digits = 1;
  for (tval = digits - 1, tens = 1; tval; tval--, tens *= 10)
    ;

  for (; digits < width; width--)
    printChar(leading);

  while (digits) {
    digits--;
    printChar('0' + ((uint8_t) (val / tens)) % 10);
    tens /= 10;
  }

  return;
}

void printString(const char *str)
{
  for (; str && *str; str++)
    printChar(*str);
  return;
}

void dumpHex(void *ptr, uint16_t count, uint16_t address)
{
  int outer, inner;
  uint8_t c;
  uint8_t *buffer = (uint8_t *) ptr;


  for (outer = 0; outer < count; outer += 16) {
    printHex(outer + address, 4, '0');
    printChar(' ');
    printChar(' ');
    for (inner = 0; inner < 16; inner++) {
      if (inner + outer < count) {
        c = buffer[inner + outer];
	printHex(c, 2, '0');
	printChar(' ');
      }
      else {
	printChar(' ');
	printChar(' ');
	printChar(' ');
      }
    }
    printChar(' ');
    printChar('|');
    for (inner = 0; inner < 16 && inner + outer < count; inner++) {
      c = buffer[inner + outer];
      if (c >= ' ' && c <= 0x7f)
	printChar(c);
      else
	printChar('.');
    }
    printChar('|');
    printChar('\r');
    printChar('\n');
  }

  return;
}

#ifndef __SCCZ80
void vconsolef(const char *format, va_list args)
{
  const char *pf;
  char leader;
  uint8_t width;


  for (pf = format; pf && *pf; pf++) {
    switch (*pf) {
    case '\n':
      printChar('\r');
      printChar('\n');
      break;

    case '%':
      pf++;
      if (!*pf)
	break;

      if (*pf == 'c')
	printChar(va_arg(args, char));
      else {
	leader = ' ';
	width = 0;

	if (isdigit(*pf)) {
	  if (*pf == '0') {
	    leader = '0';
	    pf++;
	  }

	  for (width = 0; isdigit(*pf); pf++) {
	    width *= 10;
	    width += *pf - '0';
	  }
	}

	if (*pf == 'l') {
	  pf++;
	  if (*pf == 'x')
	    printHex32(va_arg(args, uint32_t), width, leader);
	  else if (*pf == 'i' || *pf == 'd')
	    printDec32(va_arg(args, uint32_t), width, leader);
	  else if (*pf == 's')
	    printString(va_arg(args, char *));
	}
	else {
	  if (*pf == 'x')
	    printHex(va_arg(args, uint16_t), width, leader);
	  else if (*pf == 'i' || *pf == 'd')
	    printDec(va_arg(args, uint16_t), width, leader);
	  else if (*pf == 's')
	    printString(va_arg(args, char *));
	}
      }
      break;

    default:
      printChar(*pf);
      break;
    }
  }

  return;
}

void consolef(const char *format, ...)
{
  va_list args;


  va_start(args, format);
  vconsolef(format, args);
  va_end(args);
}
#endif /* ! __SCCZ80 */

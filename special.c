#include "special.h"

// Secret location in RAM for stuffing in register values to make it
// easier from a high level language.
struct {
  uint8_t C;
  uint8_t B;
  uint8_t E;
  uint8_t D;
  uint8_t L;
  uint8_t H;
  uint8_t A;
} *pt_special_regs = 0x46;

void pickles_trout_special(uint8_t func, uint8_t reg_C,
                           uint8_t reg_D, uint8_t reg_E,
                           uint8_t reg_H, uint8_t reg_L,
                           uint8_t reg_A)
{
  pt_special_regs->B = func;
  pt_special_regs->C = reg_C;
  pt_special_regs->D = reg_D;
  pt_special_regs->E = reg_E;
  pt_special_regs->H = reg_H;
  pt_special_regs->L = reg_L;
  pt_special_regs->A = reg_A;
  __asm__("call 0x0043");
  return;
}

void pickles_trout_set_date(uint8_t day_of_week, uint8_t day_of_month,
                              uint8_t month, uint8_t year)
{
  pickles_trout_special(PT_FUNC_SET_DATE, 0,       // BC
                        day_of_week, day_of_month, // DE
                        month, year,               // HL
                        0);                        // A
  return;
}

void pickles_trout_set_time(uint8_t seconds, uint8_t minutes, uint8_t hours)
{
  pickles_trout_special(PT_FUNC_SET_TIME_OF_DAY, 0, // BC
                        seconds, 0,                 // DE
                        hours, minutes,             // HL
                        0);                         // A
  return;
}

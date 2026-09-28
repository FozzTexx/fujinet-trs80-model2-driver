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

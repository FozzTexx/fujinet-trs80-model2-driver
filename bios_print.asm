; Copyright (C) 2026 Chris Osborn <fozztexx@fozztexx.com>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.

; =====================================================================
; z88dk C Binding for BIOS CONOUT Character and String Printer
; Fixed Version: Calls the clean BIOS Jump Table address directly
; =====================================================================

                XLIB    _print_char
                XLIB    _print_string

                SECTION code

; ---------------------------------------------------------------------
; void print_char(char c) __fastcall__
; Input: L = Character to print
; Self-checks an internal flag to see if BIOS lookup is required.
; ---------------------------------------------------------------------
_print_char:
                push    bc
                push    de
                push    hl

                ; 1. Check if we need to initialize the BIOS vector
                lda     init_flag       ; Load our state flag
                ora     a               ; Is it 0?
                jnz     pc_ready        ; If non-zero, skip initialization

                call    do_init         ; Run the safe initialization routine

                pop     hl              ; Restore registers to retrieve character in L
                push    hl

pc_ready:
                mov     c, l            ; BIOS CONOUT expects character in C
                call    safe_conout     ; Print character cleanly

                pop     hl
                pop     de
                pop     bc
                ret

; ---------------------------------------------------------------------
; void print_string(char *str) __fastcall__
; Input: HL = Pointer to a '$' terminated string
; ---------------------------------------------------------------------
_print_string:
                push    bc
                push    de
                push    hl

ps_loop:
                mov     a, m            ; Get character from string (pointed to by HL)
                cpi     '$'             ; Is it the standard CP/M terminator?
                jz      ps_done         ; If yes, we are finished

                mov     c, a            ; Stash the character in C
                call    safe_conout     ; Print the character safely

                inx     h               ; Move to next character in string safely
                jmp     ps_loop

ps_done:
                pop     hl
                pop     de
                pop     bc
                ret

; ---------------------------------------------------------------------
; INITIALIZATION ROUTINE
; Destroys: A, B, C, H, L
; ---------------------------------------------------------------------
do_init:
                lhld    0001h           ; HL = Address of WBOOT entry
                lxi     b, 9            ; Offset to CONOUT from WBOOT
                dad     b               ; HL = Address of 'JMP CONOUT' instruction slot
                shld    bios_vector     ; Cache the jump table pointer safely

                mvi     a, 1
                sta     init_flag       ; Set flag to 1 so we never run this again
                ret

; ---------------------------------------------------------------------
; SAFE CONOUT WRAPPER (Handles destructive BIOS implementations)
; Input: C = Character to print
; ---------------------------------------------------------------------
safe_conout:
                push    hl              ; Guard HL from BIOS corruption
                push    de              ; Guard DE from BIOS corruption

                lda     init_flag
                ora     a
                jnz     sc_execute

                ; Run initialization safely if print_string triggered first
                push    bc
                call    do_init
                pop     bc

sc_execute:
                lhld    bios_vector     ; Load direct jump table entry point address
                lxi     d, co_ret       ; Force a safe return target into DE
                push    d               ; Push target onto stack for BIOS 'RET'

                xra     a               ; Clear A register completely to remove garbage states
                pchl                    ; Jump straight to the standard BIOS table vector!

co_ret:
                pop     de              ; Restore DE safely
                pop     hl              ; Restore HL safely
                ret

                SECTION data

init_flag:      db      00h             ; 00h = uninitialized, 01h = ready
bios_vector:    dw      0000h           ; Holds direct target BIOS table vector

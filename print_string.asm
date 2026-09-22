; =====================================================================
; z88dk C Binding for BIOS CONOUT String Printer
; Uses __fastcall__ (Input string pointer is passed in HL)
; Self-managing initialization wrapper included.
; =====================================================================

                XLIB    _print_string

                SECTION code

; ---------------------------------------------------------------------
; void print_string(char *str) __fastcall__
; Input: HL = Pointer to a '$' terminated string
; Self-checks an internal flag to see if BIOS lookup is required.
; ---------------------------------------------------------------------
_print_string:
                push    bc
                push    de
                push    hl

                ; 1. Check if we need to initialize the BIOS vector
                lda     init_flag       ; Load our state flag
                ora     a               ; Is it 0?
                jnz     ps_loop         ; If non-zero, skip initialization

                ; 2. Inline Initialization Logic (runs exactly once)
                lhld    0001h           ; HL = Address of WBOOT entry
                lxi     b, 9            ; Offset to CONOUT from WBOOT
                dad     b               ; HL = Address of 'JMP CONOUT'
                shld    bios_vector     ; Cache the vector

                mvi     a, 1
                sta     init_flag       ; Set flag to 1 so we never run this again

                pop     hl              ; Restore the string pointer...
                push    hl              ; ...and re-push it to keep the stack clean

ps_loop:
                mov     a, m            ; Get character from string (pointed to by HL)
                cpi     '$'             ; Is it the standard CP/M terminator?
                jz      ps_done         ; If yes, we are finished

                mov     c, a            ; CONOUT expects char in C
                call    safe_conout     ; Print character cleanly

                inx     h               ; Move to next character in string
                jmp     ps_loop

ps_done:
                pop     hl
                pop     de
                pop     bc
                ret

; ---------------------------------------------------------------------
; SAFE CONOUT WRAPPER (Handles destructive BIOS implementations)
; Input: C = Character to print
; ---------------------------------------------------------------------
safe_conout:
                push    hl              ; Guard HL from BIOS corruption
                push    de              ; Guard DE from BIOS corruption

                lhld    bios_vector     ; Load calculated CONOUT address
                lxi     d, co_ret       ; Force a safe return target into DE
                push    d               ; Push target onto stack for BIOS 'RET'
                pchl                    ; Jump directly to BIOS vector

co_ret:
                pop     de              ; Restore DE safely
                pop     hl              ; Restore HL safely
                ret

                SECTION data

init_flag:      db      00h             ; 00h = uninitialized, 01h = ready
bios_vector:    dw      0000h           ; Holds target BIOS entry point

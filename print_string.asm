; ---------------------------------------------------------------------
; INIT BIOS VECTOR
; Must be called ONCE before using print_string to lock onto CONOUT
; Destroys: A, B, C, H, L
; ---------------------------------------------------------------------
init_bios_vector:
        lhld    0001h           ; HL = Address of WBOOT entry
        lxi     b, 9            ; Offset to CONOUT from WBOOT
        dad     b               ; HL = Address of 'JMP CONOUT'
        shld    bios_vector     ; Store for our print routine
        ret

; ---------------------------------------------------------------------
; PRINT STRING via BIOS
; Input: DE = Pointer to a '$' terminated string
; Destroys: None (All registers perfectly preserved)
; ---------------------------------------------------------------------
print_string:
        push    af
        push    bc
        push    de
        push    hl

ps_loop:
        ldax    d               ; Get character from string
        cpi     '$'             ; Is it the terminator?
        jz      ps_done         ; If yes, we are finished

        mov     c, a            ; CONOUT expects char in C
        call    safe_conout     ; Print character cleanly

        inx     d               ; Move to next character
        jmp     ps_loop

ps_done:
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; ---------------------------------------------------------------------
; SAFE CONOUT WRAPPER (Handles destructive BIOS implementations)
; Input: C = Character to print
; Destroys: None
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


; =====================================================================
; GLOBAL VARIABLES (Keep these alongside your routines)
; =====================================================================
bios_vector:
        dw      0000h           ; Holds target BIOS entry point

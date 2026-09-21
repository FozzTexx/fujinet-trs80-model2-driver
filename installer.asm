; ======================================================================
; TSR INSTALLER
;
; Run once as a normal .COM program after CP/M has booted. Finds the
; real BIOS jump table, auto-detects the next unused drive letter
; (by probing the real SELDSK for drives 0-15 and claiming the first
; one that returns a null DPH), copies the resident driver (embedded
; below as raw data, generated from tsr_resident.bin) to
; RESIDENT_BASE, saves the seven original BIOS vectors into it so it
; can chain to whatever was already handling disk I/O, and finally
; patches HOME/SELDSK/SETTRK/SETSEC/SETDMA/READ/WRITE to point at the
; resident hooks.
;
; RESIDENT_BASE below MUST match tsr_resident.z80's own RESIDENT_BASE
; exactly - both are set to reserved memory you've set aside via your
; system's "LA" (Last Address used by CP/M) option or equivalent.
; ======================================================================

	include "tsr.inc"

        ORG $0100

;; RESIDENT_SIZE:	EQU $00A0       ; bytes to copy (through the DPB's
;;                                 ; real data - DIRBUF/CSV/ALV are pure
;;                                 ; scratch space and need no content
;;                                 ; copied, only reserved memory)

; ---- offsets within the resident image (fixed, independent of
;      RESIDENT_BASE - from tsr_resident.z80's own assembly) ----
OFF_OUR_DRIVE:	EQU $0000
OFF_ORIG_HOME:	EQU $0008
OFF_ORIG_SELDSK:	EQU $000A
OFF_ORIG_SETTRK:	EQU $000C
OFF_ORIG_SETSEC:	EQU $000E
OFF_ORIG_SETDMA:	EQU $0010
OFF_ORIG_READ:	EQU $0012
OFF_ORIG_WRITE:	EQU $0014

OFF_OUR_HOME:	EQU 0*3
OFF_OUR_SELDSK:	EQU 1*3
OFF_OUR_SETTRK:	EQU 2*3
OFF_OUR_SETSEC:	EQU 3*3
OFF_OUR_SETDMA:	EQU 4*3
OFF_OUR_READ:	EQU 5*3
OFF_OUR_WRITE:	EQU 6*3

; ---- BIOS jump-table entry byte offsets (each entry = 3-byte JP) ----
JT_HOME:	EQU 8*3
JT_SELDSK:	EQU 9*3
JT_SETTRK:	EQU 10*3
JT_SETSEC:	EQU 11*3
JT_SETDMA:	EQU 12*3
JT_READ:	EQU 13*3
JT_WRITE:	EQU 14*3

start:
        ld hl,msg_installing
        call print_string

        ; ---- find BIOS base via the warm-boot vector at 0x0000 ----
        ld hl,($0001)           ; HL = operand of "JP wboot_entry"
        ld de,3
        or a
        sbc hl,de               ; HL = wboot_entry - 3 = BIOS base
        ld (bios_base),hl

        ; ---- auto-detect the next unused drive letter, using the
        ;      REAL, still-unpatched SELDSK ----
        call find_free_drive
        ld a,(free_drive)
        cp $FF
        jr nz,have_drive
        ld hl,msg_no_free_drive
        call print_string
        jp $0000                ; abort - warm boot back to CP/M
have_drive:
        ld hl,msg_claimed
        call print_string
        ld a,(free_drive)
        add a,'A'
        call print_char
        ld hl,msg_colon_nl
        call print_string

        ; ---- copy the resident driver template to RESIDENT_BASE ----
        ld hl,resident_image
        ld de,RESIDENT_BASE
        ld bc,RESIDENT_SIZE
        ldir

        ; ---- write the detected drive number into the now-live
        ;      resident image ----
        ld a,(free_drive)
        ld (RESIDENT_BASE+OFF_OUR_DRIVE),a

        ; ---- save the seven original BIOS vectors into the resident
        ;      image, then patch the jump table to point at our
        ;      hooks instead ----
        ld hl,JT_HOME
        ld de,OFF_ORIG_HOME
        call save_one_vector
        ld hl,JT_SELDSK
        ld de,OFF_ORIG_SELDSK
        call save_one_vector
        ld hl,JT_SETTRK
        ld de,OFF_ORIG_SETTRK
        call save_one_vector
        ld hl,JT_SETSEC
        ld de,OFF_ORIG_SETSEC
        call save_one_vector
        ld hl,JT_SETDMA
        ld de,OFF_ORIG_SETDMA
        call save_one_vector
        ld hl,JT_READ
        ld de,OFF_ORIG_READ
        call save_one_vector
        ld hl,JT_WRITE
        ld de,OFF_ORIG_WRITE
        call save_one_vector

        ld hl,JT_HOME
        ld de,OFF_OUR_HOME
        call patch_one_vector
        ld hl,JT_SELDSK
        ld de,OFF_OUR_SELDSK
        call patch_one_vector
        ld hl,JT_SETTRK
        ld de,OFF_OUR_SETTRK
        call patch_one_vector
        ld hl,JT_SETSEC
        ld de,OFF_OUR_SETSEC
        call patch_one_vector
        ld hl,JT_SETDMA
        ld de,OFF_OUR_SETDMA
        call patch_one_vector
        ld hl,JT_READ
        ld de,OFF_OUR_READ
        call patch_one_vector
        ld hl,JT_WRITE
        ld de,OFF_OUR_WRITE
        call patch_one_vector

        ld hl,msg_done
        call print_string
        ret                     ; back to CCP

; ----------------------------------------------------------------
; save_one_vector - IN: HL = jt_offset, DE = resident_save_offset
; Reads the CURRENT jump-table target at (bios_base+jt_offset) and
; stores it at (RESIDENT_BASE+resident_save_offset). Must be called
; BEFORE patch_one_vector touches the same jt_offset.
; ----------------------------------------------------------------
save_one_vector:
        ld (tmp_offset),de
        ld de,(bios_base)
        add hl,de
        inc hl                  ; HL = address of the JP's operand
        ld e,(hl)
        inc hl
        ld d,(hl)               ; DE = the original vector
        ld hl,(tmp_offset)
        push de
        ld de,RESIDENT_BASE
        add hl,de               ; HL = RESIDENT_BASE + resident_save_offset
        pop de
        ld (hl),e
        inc hl
        ld (hl),d
        ret

; ----------------------------------------------------------------
; patch_one_vector - IN: HL = jt_offset, DE = resident_hook_offset
; Overwrites the jump-table entry at (bios_base+jt_offset) so it
; points at (RESIDENT_BASE+resident_hook_offset) instead.
; ----------------------------------------------------------------
patch_one_vector:
        ld (tmp_offset),hl
        ld hl,RESIDENT_BASE
        add hl,de
        ld (tmp_addr),hl        ; tmp_addr = the real hook address
        ld hl,(tmp_offset)
        ld de,(bios_base)
        add hl,de
        inc hl                  ; HL = address of the JP's operand
        ld de,(tmp_addr)
        ld (hl),e
        inc hl
        ld (hl),d
        ret

; ----------------------------------------------------------------
; find_free_drive - probes the REAL (unpatched) SELDSK for drives
; 0 through 15; the first one returning HL=0 gets claimed. Result in
; (free_drive), or $FF if every drive 0-15 is already in use.
; ----------------------------------------------------------------
find_free_drive:
;;         ld b,0
;; fd_loop:
;;         push bc
;;         ld hl,(bios_base)
;;         ld de,JT_SELDSK
;;         add hl,de
;;         inc hl
;;         ld e,(hl)
;;         inc hl
;;         ld d,(hl)               ; DE = the real SELDSK entry address
;;         pop bc
;;         push bc
;;         ld c,b                  ; C = candidate drive number
;;         ex de,hl                ; HL = SELDSK entry address
;;         call call_hl
;;         ld a,h
;;         or l                    ; test the returned DPH pointer
;;         pop bc
;;         jr z,fd_found           ; HL==0 -> unconfigured -> claim it
;;         ld a,b
;;         inc a
;;         cp 16
;;         jr nc,fd_none
;;         ld b,a
;;         jr fd_loop
;; fd_found:
;;         ld a,b
	ld a,2
        ld (free_drive),a
        ret
fd_none:
        ld a,$FF
        ld (free_drive),a
        ret

; ----------------------------------------------------------------
; call_hl - "call whatever address is in HL" (transient copy for
; installer-time use, e.g. probing the real SELDSK)
; ----------------------------------------------------------------
call_hl:
        jp (hl)

; ----------------------------------------------------------------
; print_string - IN: HL = address of a $-terminated string. Uses
; BDOS function 9.
; ----------------------------------------------------------------
print_string:
        ex de,hl
        ld c,9
        call 5
        ret

; ----------------------------------------------------------------
; print_char - IN: A = character. Uses BDOS function 2.
; ----------------------------------------------------------------
print_char:
        ld e,a
        ld c,2
        call 5
        ret

; ---- installer's own working variables (transient - not resident) ----
bios_base:      dw 0
free_drive:     db 0
tmp_offset:     dw 0
tmp_addr:       dw 0

msg_installing: db "Installing custom disk driver...",13,10,'$'
msg_claimed:    db "Claiming drive ",'$'
msg_colon_nl:   db ":",13,10,'$'
msg_no_free_drive: db "No free drive letter (A-P all in use) - aborting.",13,10,'$'
msg_done:       db "Installed.",13,10,'$'

; ======================================================================
; Embedded resident driver image (raw bytes from tsr_resident.bin).
; Regenerate this block if you change tsr_resident.z80.
; ======================================================================
resident_image:
	incbin	"handler.com"
;;         db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
;;         db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$e9,$79
;;         db $21,$00,$f0,$be,$20,$09,$3e,$01,$32,$01,$f0,$21
;;         db $81,$f0,$c9,$af,$32,$01,$f0,$2a,$0a,$f0,$cd,$16
;;         db $f0,$c9,$3a,$01,$f0,$b7,$20,$04,$2a,$08,$f0,$e9
;;         db $21,$00,$00,$22,$02,$f0,$c9,$3a,$01,$f0,$b7,$20
;;         db $04,$2a,$0c,$f0,$e9,$ed,$43,$02,$f0,$c9,$3a,$01
;;         db $f0,$b7,$20,$04,$2a,$0e,$f0,$e9,$ed,$43,$04,$f0
;;         db $c9,$ed,$43,$06,$f0,$2a,$10,$f0,$e9,$3a,$01,$f0
;;         db $b7,$20,$04,$2a,$12,$f0,$e9,$af,$c9,$3a,$01,$f0
;;         db $b7,$20,$04,$2a,$14,$f0,$e9,$af,$c9,$00,$00,$00
;;         db $00,$00,$00,$00,$00,$a0,$f0,$91,$f0,$20,$f1,$30
;;         db $f1,$1a,$00,$03,$07,$00,$f2,$00,$3f,$00,$c0,$00
;;         db $00,$00,$00,$00
RESIDENT_SIZE:	 EQU $ - resident_image

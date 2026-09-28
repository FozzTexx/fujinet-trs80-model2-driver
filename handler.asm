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

; ======================================================================
; handler.asm - resident BIOS shim
;
; Assembled with ORG = RESIDENT_BASE (adjust to your reserved memory,
; must match the installer). Handles chaining (is this request for our
; drive, or should it pass through to whatever was already there?) and
; register-convention adaptation, then forwards the real work to C
; functions built with z88dk. Nothing here implements actual disk
; logic - see driver.c for that.
;
; EXTERN C functions (z88dk emits a leading underscore):
;   void   bios_home(void)
;   void  *bios_seldsk(uint8_t drive)      __z88dk_fastcall
;   void   bios_settrk(uint16_t track)     __z88dk_fastcall
;   void   bios_setsec(uint16_t sector)    __z88dk_fastcall
;   void   bios_setdma(uint16_t addr)      __z88dk_fastcall
;   uint8_t bios_read(void)
;   uint8_t bios_write(uint8_t deblock)    __z88dk_fastcall
;
; z88dk __z88dk_fastcall: single 8-bit param in A, single 16-bit/
; pointer param in HL. Returns: 8-bit in A, 16-bit/pointer in HL -
; this happens to match CP/M's own BIOS conventions exactly, so most
; hooks below just move the CP/M input register into place, CALL,
; and RET straight through with no further conversion needed.
;
; VERIFY the exact fastcall register assignment against your actual
; z88dk build before trusting this - it can vary by backend/version.
; ======================================================================

	include	"tsr.inc"

	public _our_drive

        ORG RESIDENT_BASE

; ======================================================================
; FIXED JUMP TABLE - this is the entire ABI the installer depends on.
; Every entry is a 3-byte "JP" at a fixed index * 3 offset from
; RESIDENT_BASE, in this exact order, forever. Everything below the
; table (routines, variables, their order, their sizes) is free to
; change without touching the installer at all - it only ever calls
; through these 15 fixed slots, the same way real CP/M BIOS code only
; ever gets called through the real jump table rather than by knowing
; internal BIOS addresses.
;
;   index  purpose                              called by
;   -----  -----------------------------------   ---------
;    0     our_home     (BIOS-facing hook)        real BIOS, after patch
;    1     our_seldsk   (BIOS-facing hook)        real BIOS, after patch
;    2     our_settrk   (BIOS-facing hook)        real BIOS, after patch
;    3     our_setsec   (BIOS-facing hook)        real BIOS, after patch
;    4     our_setdma   (BIOS-facing hook)        real BIOS, after patch
;    5     our_read     (BIOS-facing hook)        real BIOS, after patch
;    6     our_write    (BIOS-facing hook)        real BIOS, after patch
;    7     set_our_drive     (IN: A = drive #)    installer, once
;    8     set_orig_home     (IN: HL = vector)    installer, once
;    9     set_orig_seldsk   (IN: HL = vector)    installer, once
;   10     set_orig_settrk   (IN: HL = vector)    installer, once
;   11     set_orig_setsec   (IN: HL = vector)    installer, once
;   12     set_orig_setdma   (IN: HL = vector)    installer, once
;   13     set_orig_read     (IN: HL = vector)    installer, once
;   14     set_orig_write    (IN: HL = vector)    installer, once
; ======================================================================

jump_table:
        jp our_home             ; index 0
        jp our_seldsk           ; index 1
        jp our_settrk           ; index 2
        jp our_setsec           ; index 3
        jp our_setdma           ; index 4
        jp our_read             ; index 5
        jp our_write            ; index 6
	jp our_init		; index 7

; ----------------------------------------------------------------
; Saved state - filled in once by the installer
; ----------------------------------------------------------------
_our_drive:     db 0            ; which drive letter we claimed (0=A:)
mine_flag:      db 0            ; nonzero if the CURRENTLY SELECTED
                                ; drive is ours

orig_home:      dw 0            ; saved original BIOS vectors, so we
orig_seldsk:    dw 0            ; can chain to whatever else was
orig_settrk:    dw 0            ; already handling disk I/O (other
orig_setsec:    dw 0            ; drives, floppies, etc.)
orig_setdma:    dw 0
orig_read:      dw 0
orig_write:     dw 0

        EXTERN _bios_home
        EXTERN _bios_seldsk
        EXTERN _bios_settrk
        EXTERN _bios_setsec
        EXTERN _bios_setdma
        EXTERN _bios_read
        EXTERN _bios_write
	EXTERN _bios_init

; ----------------------------------------------------------------
; call_hl - standard "call whatever address is in HL" idiom
; ----------------------------------------------------------------
call_hl:
        jp (hl)

; ----------------------------------------------------------------
; our_seldsk - IN: C = drive number, E&1 = new. OUT: HL = DPH ptr, or 0.
; ----------------------------------------------------------------
our_seldsk:
        ld a,c
        ld hl,_our_drive
        cp (hl)
        jr nz,seldsk_not_ours
        ld a,1
        ld (mine_flag),a
        ld l,c                  ; fastcall wants the drive number in L
	ld (saved_sp),sp	; Preserve caller's stack
	ld sp,our_stack_top	; Use our stack
        call _bios_seldsk       ; returns HL = DPH ptr directly
	ld sp,(saved_sp)	; Restore caller's stack
        ret
seldsk_not_ours:
        xor a
        ld (mine_flag),a
        ld hl,(orig_seldsk)
        call call_hl
        ret

; ----------------------------------------------------------------
; our_home - no parameters
; ----------------------------------------------------------------
our_home:
        ld a,(mine_flag)
        or a
        jr nz,home_ours
        ld hl,(orig_home)
        jp (hl)                 ; tail-chain - let the original's own
                                ; RET return directly to our caller
home_ours:
	ld (saved_sp),sp	; Preserve caller's stack
	ld sp,our_stack_top	; Use our stack
        call _bios_home
	ld sp,(saved_sp)	; Restore caller's stack
        ret

; ----------------------------------------------------------------
; our_settrk - IN: BC = track number
; ----------------------------------------------------------------
our_settrk:
        ld a,(mine_flag)
        or a
        jr nz,settrk_ours
        ld hl,(orig_settrk)
        jp (hl)
settrk_ours:
        ld hl,bc                ; fastcall wants the 16-bit value in HL
	ld (saved_sp),sp	; Preserve caller's stack
	ld sp,our_stack_top	; Use our stack
        call _bios_settrk
	ld sp,(saved_sp)	; Restore caller's stack
        ret

; ----------------------------------------------------------------
; our_setsec - IN: BC = sector number
; ----------------------------------------------------------------
our_setsec:
        ld a,(mine_flag)
        or a
        jr nz,setsec_ours
        ld hl,(orig_setsec)
        jp (hl)
setsec_ours:
        ld h,b
        ld l,c
	ld (saved_sp),sp	; Preserve caller's stack
	ld sp,our_stack_top	; Use our stack
        call _bios_setsec
	ld sp,(saved_sp)	; Restore caller's stack
        ret

; ----------------------------------------------------------------
; our_setdma - IN: BC = DMA address
; NOT gated by mine_flag - always record it AND always chain, since
; we don't yet know whether the READ/WRITE that follows is for our
; drive or someone else's.
; ----------------------------------------------------------------
our_setdma:
        ld h,b
        ld l,c
	ld (saved_sp),sp	; Preserve caller's stack
	ld sp,our_stack_top	; Use our stack
        call _bios_setdma       ; unconditionally tell our own C code
	ld sp,(saved_sp)	; Restore caller's stack
        ld hl,(orig_setdma)
        jp (hl)                 ; ...and unconditionally chain too
                                ; (tail-chain: its own RET returns to
                                ; whoever called us)

; ----------------------------------------------------------------
; our_read - no parameters. OUT: A = 0 ok, 1 = error
; ----------------------------------------------------------------
our_read:
        ld a,(mine_flag)
        or a
        jr nz,read_ours
        ld hl,(orig_read)
        jp (hl)
read_ours:
	ld (saved_sp),sp	; Preserve caller's stack
	ld sp,our_stack_top	; Use our stack
        call _bios_read         ; returns status in L
	ld sp,(saved_sp)	; Restore caller's stack
	ld a,l			; CP/M wants status in A
        ret

; ----------------------------------------------------------------
; our_write - IN: C = deblocking flag (0/1/2). OUT: A = 0 ok, 1 error
; ----------------------------------------------------------------
our_write:
        ld a,(mine_flag)
        or a
        jr nz,write_ours
        ld hl,(orig_write)
        jp (hl)
write_ours:
        ld l,c                  ; fastcall wants the flag in L
	ld (saved_sp),sp	; Preserve caller's stack
	ld sp,our_stack_top	; Use our stack
        call _bios_write        ; returns status in L
	ld sp,(saved_sp)	; Restore caller's stack
	ld a,l			; CP/M wants status in A
        ret

; ----------------------------------------------------------------
; our_init - no parameters. Print FujiNet version, set date & time
; ----------------------------------------------------------------
our_init:
	ld (saved_sp),sp	; Preserve caller's stack
	ld sp,our_stack_top	; Use our stack
        call _bios_init
	ld sp,(saved_sp)	; Restore caller's stack
	ret

saved_sp:
	dw 0
our_stack:
	defs 256
our_stack_top:

resident_end:

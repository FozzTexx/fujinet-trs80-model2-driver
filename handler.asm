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

        ORG RESIDENT_BASE

        EXTERN _bios_home
        EXTERN _bios_seldsk
        EXTERN _bios_settrk
        EXTERN _bios_setsec
        EXTERN _bios_setdma
        EXTERN _bios_read
        EXTERN _bios_write

; ----------------------------------------------------------------
; Saved state - filled in once by the installer
; ----------------------------------------------------------------
our_drive:      db 0            ; which drive letter we claimed (0=A:)
mine_flag:      db 0            ; nonzero if the CURRENTLY SELECTED
                                ; drive is ours

orig_home:      dw 0            ; saved original BIOS vectors, so we
orig_seldsk:    dw 0            ; can chain to whatever else was
orig_settrk:    dw 0            ; already handling disk I/O (other
orig_setsec:    dw 0            ; drives, floppies, etc.)
orig_setdma:    dw 0
orig_read:      dw 0
orig_write:     dw 0

; ----------------------------------------------------------------
; call_hl - standard "call whatever address is in HL" idiom
; ----------------------------------------------------------------
call_hl:
        jp (hl)

; ----------------------------------------------------------------
; our_seldsk - IN: C = drive number. OUT: HL = DPH ptr, or 0.
; ----------------------------------------------------------------
our_seldsk:
        ld a,c
        ld hl,our_drive
        cp (hl)
        jr nz,seldsk_not_ours
        ld a,1
        ld (mine_flag),a
        ld a,c                  ; fastcall wants the drive number in A
                                ; (redundant with the compare above,
                                ; but keeps the two paths symmetric)
        call _bios_seldsk       ; returns HL = DPH ptr directly
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
        call _bios_home
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
        ld h,b
        ld l,c                  ; fastcall wants the 16-bit value in HL
        call _bios_settrk
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
        call _bios_setsec
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
        call _bios_setdma       ; unconditionally tell our own C code
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
        call _bios_read         ; returns A = status directly
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
        ld a,c                  ; fastcall wants the flag in A
        call _bios_write        ; returns A = status directly
        ret

; ======================================================================
; Standard CP/M 2.2 DPH (Disk Parameter Header) and DPB (Disk
; Parameter Block). ADJUST THE DPB VALUES to match your actual custom
; device's real geometry - the numbers below are placeholders only.
; ======================================================================

our_dph:
        dw 0            ; XLT  - sector translate table (0 = none)
        dw 0,0,0        ; scratch (BC, DE, HL) - used by BDOS itself
        dw our_dirbuf   ; DIRBUF - 128-byte scratch directory buffer
        dw our_dpb      ; DPB - this drive's parameter block, below
        dw our_csv      ; CSV - checksum vector
        dw our_alv      ; ALV - allocation vector

; PLACEHOLDER geometry - replace every value with your real device's
our_dpb:
        dw 26           ; SPT - sectors per (logical 128-byte) track
        db 3            ; BSH - block shift factor
        db 7            ; BLM - block mask
        db 0            ; EXM - extent mask
        dw 242          ; DSM - max block number
        dw 63           ; DRM - max directory entry number
        db 0C0h         ; AL0 - directory allocation bitmap
        db 0            ; AL1
        dw 0            ; CKS - directory check vector size (0 = fixed
                        ; disk, not checked)
        dw 0            ; OFF - reserved (system) tracks

our_dirbuf:     ds 128
our_csv:        ds 16   ; size depends on your real DRM
our_alv:        ds 31   ; size depends on your real DSM

resident_end:

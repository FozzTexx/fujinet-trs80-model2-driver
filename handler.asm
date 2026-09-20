; ======================================================================
; TSR RESIDENT PORTION
;
; Assembled with ORG = RESIDENT_BASE, i.e. wherever you've reserved
; memory via your system's "LA" (Last Address used by CP/M) setting.
; This file is assembled standalone; the installer (tsr_installer.z80)
; embeds its assembled bytes as a raw data block and LDIRs them to
; RESIDENT_BASE at install time, then patches the real BIOS jump table
; to point at the hook entry points below. Because this is assembled
; with the correct final origin from the start, none of P&T's
; relocation problems apply here - every address below is already
; correct for where this code will actually run.
;
; ADJUST RESIDENT_BASE to wherever you've reserved space. Nothing else
; in this file needs to change if you do.
; ======================================================================

	include "tsr.inc"

        ORG RESIDENT_BASE

; ----------------------------------------------------------------
; Saved state - filled in once by the installer, read/written by
; the hooks below
; ----------------------------------------------------------------
our_drive:      db 0            ; which drive letter we claimed (0=A:)
mine_flag:      db 0            ; nonzero if the CURRENTLY SELECTED
                                ; drive is ours (set by our_seldsk,
                                ; checked by our_home/settrk/setsec/
                                ; setdma/read/write)
cur_track:      dw 0            ; last track number set via SETTRK,
                                ; while our drive is selected
cur_sector:     dw 0            ; last sector number set via SETSEC
cur_dma:        dw 0            ; last DMA address set via SETDMA

orig_home:      dw 0            ; saved original BIOS vectors -
orig_seldsk:    dw 0            ; filled in by the installer before
orig_settrk:    dw 0            ; the jump table gets patched, so we
orig_setsec:    dw 0            ; can chain to whatever else was
orig_setdma:    dw 0            ; already handling disk I/O (other
orig_read:      dw 0            ; drives, floppies, etc.)
orig_write:     dw 0

; ----------------------------------------------------------------
; call_hl - standard Z80 idiom for "call whatever address is in HL".
; CALL pushes the return address, then we JP (HL); when the target
; routine does its own RET, it pops that same return address and
; control comes back to whoever did "CALL call_hl".
; ----------------------------------------------------------------
call_hl:
        jp (hl)

; ----------------------------------------------------------------
; our_seldsk - hooked SELDSK entry point.
; IN:  C = drive number requested
; OUT: HL = DPH pointer, or 0 if not a valid drive
; ----------------------------------------------------------------
our_seldsk:
        ld a,c
        ld hl,our_drive
        cp (hl)
        jr nz,seldsk_not_ours
        ; it's our drive - remember that, and hand back our DPH
        ld a,1
        ld (mine_flag),a
        ld hl,our_dph
        ret
seldsk_not_ours:
        xor a
        ld (mine_flag),a
        ld hl,(orig_seldsk)
        call call_hl
        ret

; ----------------------------------------------------------------
; our_home - hooked HOME entry point (no parameters; operates on
; whichever drive was most recently selected)
; ----------------------------------------------------------------
our_home:
        ld a,(mine_flag)
        or a
        jr nz,home_ours
        ld hl,(orig_home)
        jp (hl)                 ; tail-chain - let the original HOME's
                                ; own RET return directly to whoever
                                ; called us
home_ours:
        ld hl,0
        ld (cur_track),hl       ; "home" = seek to track 0
        ; TODO: hardware-specific: actually seek your device to
        ; cylinder/track 0 here
        ret

; ----------------------------------------------------------------
; our_settrk - hooked SETTRK entry point. IN: BC = track number
; ----------------------------------------------------------------
our_settrk:
        ld a,(mine_flag)
        or a
        jr nz,settrk_ours
        ld hl,(orig_settrk)
        jp (hl)
settrk_ours:
        ld (cur_track),bc
        ret

; ----------------------------------------------------------------
; our_setsec - hooked SETSEC entry point. IN: BC = sector number
; ----------------------------------------------------------------
our_setsec:
        ld a,(mine_flag)
        or a
        jr nz,setsec_ours
        ld hl,(orig_setsec)
        jp (hl)
setsec_ours:
        ld (cur_sector),bc
        ret

; ----------------------------------------------------------------
; our_setdma - hooked SETDMA entry point. IN: BC = DMA address.
; NOTE: unlike the others, this one is NOT gated by mine_flag - we
; always record it AND always chain to the original, since we don't
; yet know whether the READ/WRITE that follows will be for our
; drive or someone else's. Keeping both copies current is cheap and
; avoids ever using a stale DMA address.
; ----------------------------------------------------------------
our_setdma:
        ld (cur_dma),bc
        ld hl,(orig_setdma)
        jp (hl)                 ; tail-chain unconditionally

; ----------------------------------------------------------------
; our_read - hooked READ entry point. OUT: A=0 ok, A=1 error
; ----------------------------------------------------------------
our_read:
        ld a,(mine_flag)
        or a
        jr nz,read_ours
        ld hl,(orig_read)
        jp (hl)
read_ours:
        ; TODO: hardware-specific: perform the actual read using
        ; (cur_track), (cur_sector), (cur_dma), and your device's
        ; own I/O ports/protocol. Return A=0 on success, A=1 on error.
        xor a
        ret

; ----------------------------------------------------------------
; our_write - hooked WRITE entry point. IN: C = deblocking flag
; (0/1/2, standard CP/M meaning). OUT: A=0 ok, A=1 error
; ----------------------------------------------------------------
our_write:
        ld a,(mine_flag)
        or a
        jr nz,write_ours
        ld hl,(orig_write)
        jp (hl)
write_ours:
        ; TODO: hardware-specific: perform the actual write using
        ; (cur_track), (cur_sector), (cur_dma), C (deblocking flag),
        ; and your device's own I/O ports/protocol.
        xor a
        ret

; ======================================================================
; Standard CP/M 2.2 DPH (Disk Parameter Header) and DPB (Disk
; Parameter Block). ADJUST THE DPB VALUES to match your actual custom
; device's real geometry - the numbers below are placeholders only
; and will not correspond to any real disk.
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

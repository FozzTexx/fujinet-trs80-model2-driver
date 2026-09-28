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

	include	"portio.inc"
	public	_port_init

; ======================================================================
; port_init(ctc_divisor, sio_divisor)
;
; sccz80 __CALLEE__:
;
;   stack on entry:
;       return address
;       ctc_divisor
;       sio_divisor
;
; Both uint8_t arguments occupy a word on the stack.
; ======================================================================

_port_init:

    pop ix                  ; save return address
    pop de                  ; DE = sio_divisor
    pop bc                  ; BC = ctc_divisor
    push ix                 ; callee has now removed the arguments

    ; --------------------------------------------------------------
    ; Reset SIO channel
    ; --------------------------------------------------------------

    xor a
    out (SIO_CTRL),a        ; select WR0

    ld a,SIO_RESET
    out (SIO_CTRL),a        ; reset channel

    ; --------------------------------------------------------------
    ; Disable SIO interrupts
    ; --------------------------------------------------------------

    ld a,1
    out (SIO_CTRL),a        ; select WR1

    ld a,SIO_WR1
    out (SIO_CTRL),a

    ; --------------------------------------------------------------
    ; Configure asynchronous clock multiplier.
    ;
    ; 1  -> x1
    ; 16 -> x16
    ; 32 -> x32
    ; 64 -> x64
    ;
    ; Anything else defaults to x16.
    ; --------------------------------------------------------------

    ld a,e

    cp 1
    jr z,sio_x1

    cp 16
    jr z,sio_x16

    cp 32
    jr z,sio_x32

    cp 64
    jr z,sio_x64

    ; Default to x16
    ld a,$44
    jr sio_wr4

sio_x1:
    ld a,$04
    jr sio_wr4

sio_x16:
    ld a,$44
    jr sio_wr4

sio_x32:
    ld a,$84
    jr sio_wr4

sio_x64:
    ld a,$C4

sio_wr4:
    ld d,a

    ld a,4
    out (SIO_CTRL),a        ; select WR4

    ld a,d
    out (SIO_CTRL),a

    ; --------------------------------------------------------------
    ; Receiver
    ; --------------------------------------------------------------

    ld a,3
    out (SIO_CTRL),a        ; select WR3

    ld a,SIO_WR3
    out (SIO_CTRL),a

    ; --------------------------------------------------------------
    ; Transmitter
    ; --------------------------------------------------------------

    ld a,5
    out (SIO_CTRL),a        ; select WR5

    ld a,SIO_WR5
    out (SIO_CTRL),a

    ; --------------------------------------------------------------
    ; Configure CTC serial clock(s)
    ; --------------------------------------------------------------

    ld a,CTC_COUNTER
    out (CTC_RX),a

    ld a,c
    out (CTC_RX),a

IF PORT = PORT_A

    ; Port A has separate receive and transmit clocks.

    ld a,CTC_COUNTER
    out (CTC_TX),a

    ld a,c
    out (CTC_TX),a

ENDIF

    ret

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

;; extern int __FASTCALL__ port_getc_timeout(uint16_t timeout);
;; timeout is in HL
;; loop until data is available or timeout elapses
;; Destroys: AF, BC, HL
;; Preserves: DE, IX, IY
_port_getc_timeout:
    ; HL = timeout in milliseconds

@millisecond:
    ; Check for a character while waiting approximately 1 ms.
    ; At 4 MHz, this loop is approximately 20 us per iteration.
	ld	b,50

@poll:
	xor	a
	out	(SIO_CTRL),a
	in	a,(SIO_CTRL)
	bit	SIO_RX_READY,a
	jr	nz,@got_character

	djnz	@poll

    ; One millisecond has elapsed.
	dec	hl
	ld	a,h
	or	l
	jr	nz,@millisecond

@timeout:
	ld	hl,-1
	ret

@got_character:
	in	a,(SIO_DATA)
	ld	h,0
	ld	l,a
	ret

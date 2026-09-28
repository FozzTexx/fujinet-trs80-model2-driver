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
	public	_port_putc

;; extern int __FASTCALL__ port_putc(uint8_t c);
;; writes data in L to port, no return value
_port_putc:
	in	a,(SIO_CTRL)	; get transmit flags
	bit	SIO_TX_EMPTY,a	; check if able to send
	jr	z,_port_putc	; not yet
	ld	a,l		; can't write L directly to address
	out	(SIO_DATA),a	; send data out port
	ret

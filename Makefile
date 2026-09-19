fujitsr2.com: installer.asm fujitsr.com
	z80asm -o $@ --list=$(basename $<).lst $<

fujitsr.com: fujitsr.asm

%.com: %.asm
	z80asm -o $@ --list=$(basename $<).lst $<

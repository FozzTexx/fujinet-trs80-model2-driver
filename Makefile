fujitsr2.com: installer.asm handler.com
	z80asm -o $@ --list=$(basename $<).lst $<

handler.com: handler.asm

findlet.com: findlet.asm

%.com: %.asm
	z80asm -o $@ --list=$(basename $<).lst $<

AS = zcc

fujitsr2.com: installer.asm handler.com
	$(AS) +cpm --no-crt -o=$@ $<

handler.com: handler.asm

findlet.com: findlet.asm

%.com: %.asm
	$(AS) +cpm --no-crt -o=$@ $<

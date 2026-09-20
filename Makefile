AS = zcc
PORTIO_OBJ = port_getbuf_slip_dual.o port_getc_timeout.o port_init.o port_putbuf_slip.o \
	     port_putc.o
FUJIBUS_OBJ = fuji_bus_call.o
DISK_OBJ = disk.o
HANDLER = handler

fujitsr2.com: installer.asm $(HANDLER).com tsr.inc
	$(AS) +cpm --no-crt -o=$@ $<

$(HANDLER).com: $(HANDLER).asm $(PORTIO_OBJ) $(FUJIBUS_OBJ) $(DISK_OBJ)

$(DISK_OBJ): disk.h fuji_bus_call.h
$(FUJIBUS_OBJ): fuji_bus_call.h portio.h
$(PORTIO_OBJ): portio.inc
$(HANDLER).asm: tsr.inc

%.com: %.asm
	$(AS) +cpm --no-crt -o $@ $^

%.o: %.s
	$(AS) -l -o=$@ $<
%.o: %.c
	zcc +cpm -c -o $@ $<

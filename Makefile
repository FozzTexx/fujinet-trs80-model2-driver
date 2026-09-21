AS = z80asm
CC = zcc
ASFLAGS =
CFLAGS = +cpm --no-crt
PORTIO_OBJ = port_getbuf_slip_dual.o port_getc_timeout.o port_init.o port_putbuf_slip.o \
	     port_putc.o
FUJIBUS_OBJ = fuji_bus_call.o
DISK_OBJ = disk.o
HANDLER = handler
INSTALLER_OBJ = installer.o

fujitsr2.com: $(INSTALLER_OBJ) $(HANDLER).com tsr.inc
	$(CC) $(CFLAGS) -o=$@ $<

$(HANDLER).com: $(HANDLER).asm $(PORTIO_OBJ) $(FUJIBUS_OBJ) $(DISK_OBJ)

$(DISK_OBJ): disk.h fuji_bus_call.h
$(FUJIBUS_OBJ): fuji_bus_call.h portio.h
$(PORTIO_OBJ): portio.inc
$(HANDLER).asm: tsr.inc

%.com: %.asm
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.asm
	$(AS) $(ASFLAGS) -o=$@ $<
%.o: %.s
	$(AS) $(ASFLAGS) -o=$@ $<
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

contest.com: contest.asm

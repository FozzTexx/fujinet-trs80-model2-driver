AS = z80asm
CC = zcc
ASFLAGS = -l
CFLAGS = +cpm -m
PORTIO_OBJ = port_getbuf_slip_dual.o port_getc_timeout.o port_init.o port_putbuf_slip.o \
	     port_putc.o
FUJIBUS_OBJ = fuji_bus_call.o
DISK_OBJ = disk.o
SPECIAL_OBJ = special.o
PRINT_OBJ = bios_print.o print.o
HANDLER = handler
INSTALLER_OBJ = installer.o

fujitsr2.com: $(INSTALLER_OBJ) $(HANDLER).com tsr.inc
	$(CC) $(CFLAGS) --no-crt -o=$@ $<

$(HANDLER).com: $(HANDLER).o $(PORTIO_OBJ) $(FUJIBUS_OBJ) $(DISK_OBJ) \
		$(PRINT_OBJ) $(SPECIAL_OBJ)
	$(CC) $(CFLAGS) --no-crt -o $@ $^

$(DISK_OBJ): disk.h fuji_bus_call.h special.h
$(FUJIBUS_OBJ): fuji_bus_call.h portio.h
$(PORTIO_OBJ): portio.inc
$(HANDLER).o: $(HANDLER).asm tsr.inc
$(INSTALLER_OBJ): installer.asm tsr.inc $(HANDLER).com
$(SPECIAL_OBJ): special.h
print.o: print.h print.c

# %.com: %.asm
# 	$(CC) $(CFLAGS) -o $@ $^

%.o: %.asm
	$(AS) $(ASFLAGS) -o=$@ $<
%.o: %.s
	$(AS) $(ASFLAGS) -o=$@ $<
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

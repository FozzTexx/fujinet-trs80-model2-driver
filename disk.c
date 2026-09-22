#include "disk.h"
#include "cpm_dph.h"
#include "fuji_bus_call.h"

extern uint8_t our_drive;
extern void print_string(uint8_t *str) __z88dk_fastcall;

static struct CPM_DPB current_dpb = {
    .spt = 26,   /* 26 logical sectors per track */
    .bsh = 3,    /* Block shift factor: 3 (translates to 1KB allocation blocks) */
    .blm = 7,    /* Block mask: 2^3 - 1 = 7 */
    .exm = 0,    /* Extent mask: 0 (since max block size <= 255 and disk < 256 blocks) */
    .dsm = 242,  /* Total logical allocation blocks minus 1 (243 total blocks) */
    .drm = 63,   /* Total directory entries minus 1 (Allows for 64 files max) */
    .al0 = 0xC0, /* Binary 11000000: Claims the first 2 blocks (Blocks 0 & 1) for directory storage */
    .al1 = 0x00, /* Binary 00000000 */
    .cks = 16,   /* Checksum vector size: (DRM + 1) / 4 -> 64 / 4 = 16 bytes */
    .off = 2     /* 2 reserved tracks at the beginning of the disk for system boot tracking */
};

/* Standard 8" SSSD Skew Table (6-sector interleave) */
static const uint8_t current_skew[26] = {
    1,  7, 13, 19, 25,  5, 11, 17, 23,  3,  9, 15, 21,
    2,  8, 14, 20, 26,  6, 12, 18, 24,  4, 10, 16, 22
};

/* The shared 128-byte directory scratchpad */
static uint8_t shared_dirbuf[128];

/* Drive-specific scratchpad RAM vectors (Drive A) */
static uint8_t driveA_csv[16];
static uint8_t driveA_alv[32];

/* The final assigned DPH for Drive A */
static struct CPM_DPH current_dph = {
    .xlt      = current_skew,
    .scratch1 = 0,
    .scratch2 = 0,
    .scratch3 = 0,
    .dirbuf   = { .raw_bytes = shared_dirbuf },
    .dpb      = &current_dpb,
    .csv      = driveA_csv,
    .alv      = driveA_alv
};

static uint8_t current_drive = 0;
static uint16_t current_track = 0;
static uint8_t current_sector = 0;
static uint8_t *dma_buffer = (uint8_t *) 0x0080; /* Default CP/M DMA address */

void bios_home(void)
{
  current_track = 0;
}

void *bios_seldsk(uint8_t drive)
{
  print_string("FUJI SELDSK\r\n$");
  current_drive = drive - our_drive;
  return &current_dph;
}

void bios_settrk(uint16_t track)
{
  current_track = track;
}

void bios_setsec(uint8_t sector)
{
  current_sector = sector;
}

void bios_setdma(uint16_t dma_addr)
{
  dma_buffer = (uint8_t *) dma_addr;
}

uint8_t bios_read(void)
{
  unsigned sector = current_track * SECTORS_PER_TRACK + current_sector;


  return !fuji_bus_call(FUJI_DEVICEID_DISK + current_drive,
                        DISKCMD_READ, FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                        NATIVE_SPLIT_U32(sector),
                        dma_buffer, SECTOR_SIZE);
}

uint8_t bios_write(uint8_t write_type)
{
  unsigned sector = current_track * SECTORS_PER_TRACK + current_sector;


  return !fuji_bus_call(FUJI_DEVICEID_DISK + current_drive,
                        DISKCMD_WRITE, FUJI_FIELD_C1234 | FUJI_FIELD_DATA,
                        NATIVE_SPLIT_U32(sector),
                        dma_buffer, SECTOR_SIZE);
}

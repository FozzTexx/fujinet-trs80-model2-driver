#include "disk.h"
#include "cpm_dph.h"
#include "fuji_bus_call.h"
#include "print.h"
#include <intrinsic.h>
#include <stdint.h>
#include <string.h>

#define SD_SECTOR_SIZE 128
#define DD_SECTOR_SIZE 512
#define MAX_BLOCK_SIZE DD_SECTOR_SIZE
#define TRACK_0_NUMSEC 26

#define be16toh(x) intrinsic_swap_endian_16(x)
#define htobe16(x) intrinsic_swap_endian_16(x)

extern uint8_t our_drive;

typedef struct {
  uint8_t num_tracks;
  uint8_t step_rate;
  uint16_t sectors_per_track; // big endian
  uint8_t num_sides;
  uint8_t density;
  uint16_t sector_size; // big endian
  uint8_t drive_present;
  uint8_t reserved1;
  uint8_t reserved2;
  uint8_t reserved3;
} _percomBlock;

static struct CPM_DPB sd_dpb = {
  .spt = 26,   /* 26 logical sectors per track */
  .bsh = 3,    /* Block shift factor: 3 (translates to 1KB allocation blocks) */
  .blm = 7,    /* Block mask: 2^3 - 1 = 7 */
  .exm = 0,    /* Extent mask: 0 (since max block size <= 255 and disk < 256 blocks) */
  .dsm = 242,  /* Total logical allocation blocks minus 1 (243 total blocks) */
  .drm = 63,   /* Total directory entries minus 1 (Allows for 64 files max) */
  .al0 = 0xC0, /* Binary 11001011: Blocks, 0, 1, 3, 6, 7 for directory storage */
  .al1 = 0x00, /* Binary 00000000 */
  .cks = 16,   /* Checksum vector size: (DRM + 1) / 4 -> 64 / 4 = 16 bytes */
  .off = 2     /* 2 reserved tracks at the beginning of the disk for system boot tracking */
};

static struct CPM_DPB dd_dpb = {
  .spt = 64,
  .bsh = 4,
  .blm = 15,
  .exm = 0,
  .dsm = 299,
  .drm = 127,
  .al0 = 0xC0,
  .al1 = 0x00,
  .cks = 32,
  .off = 2
};

/* DD 512 byte sectors:
   40 00 04 0F 00 2B 01 7F 00 CB 00 20 00 02

   SD 128 byte sectors
   1A 00 03 07 00 F2 00 3F 00 CB 00 10 00 02
*/

/* Standard 8" SSSD Skew Table (6-sector interleave) */
static const uint8_t sd_skew[26] = {
  1,  7, 13, 19, 25,  5, 11, 17, 23,  3,  9, 15, 21,
  2,  8, 14, 20, 26,  6, 12, 18, 24,  4, 10, 16, 22
};

/* Standard 8" SSSD Skew Table (6-sector interleave) */
static const uint8_t dd_skew[64] = {
   0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
  32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63
};

/* The shared 128-byte directory scratchpad */
static uint8_t shared_dirbuf[128];

/* Drive-specific scratchpad RAM vectors (Drive A) */
static uint8_t driveA_csv[16];
static uint8_t driveA_alv[32];

/* The final assigned DPH for Drive A */
static struct CPM_DPH current_dph = {
    .xlt      = sd_skew,
    .scratch1 = 0,
    .scratch2 = 0,
    .scratch3 = 0,
    .dirbuf   = { .raw_bytes = shared_dirbuf },
    .dpb      = &sd_dpb,
    .csv      = driveA_csv,
    .alv      = driveA_alv
};

static uint8_t current_drive = 0xFF;
static uint16_t current_track = 0;
static uint8_t current_sector = 0;
static uint8_t *dma_buffer = (uint8_t *) 0x0080; /* Default CP/M DMA address */

static _percomBlock geometry;
static uint16_t last_block;
static uint8_t block_buffer[MAX_BLOCK_SIZE];

void bios_home(void)
{
  current_track = 0;
}

void *bios_seldsk(uint8_t drive) __z88dk_fastcall
{
  bool success = 0;
  uint16_t sector_size;


#ifdef UNUSED
  printString("FUJI SELDSK ");
  printDec(drive, 0, 0);
  printString(" ");
  printDec(our_drive, 0, 0);
  printString("\r\n");
#endif /* UNUSED */
  drive -= our_drive;
  if (current_drive != drive) {
    current_drive = drive;
    last_block = 0xffff;
  }

  // FIXME - check if disk has changed
  success = fuji_bus_call(FUJI_DEVICEID_DISK + current_drive,
                          DISKCMD_PERCOM_READ,
                          FUJI_FIELD_REPLY,
                          0, 0, 0, 0,
                          &geometry, sizeof(geometry));
  if (!success)
    return NULL;

#ifdef UNUSED
  printString("FUJI GEOMETRY SPT=");
  printDec(be16toh(geometry.sectors_per_track), 0, 0);
  printString(" NT=");
  printDec(geometry.num_tracks, 0, 0);
  printString(" SS=");
  printDec(be16toh(geometry.sector_size), 0, 0);
  printString(" NS=");
  printDec(geometry.num_sides, 0, 0);
  printString("\r\n");
#endif /* UNUSED */

  sector_size = be16toh(geometry.sector_size);
  if (sector_size == SD_SECTOR_SIZE) {
    current_dph.dpb = &sd_dpb;
    current_dph.xlt = sd_skew;
  }
  else if (sector_size == DD_SECTOR_SIZE) {
    current_dph.dpb = &dd_dpb;
    current_dph.xlt = dd_skew;
  }
  else
    return NULL;

  return &current_dph;
}

void bios_settrk(uint16_t track) __z88dk_fastcall
{
  current_track = track;
}

void bios_setsec(uint8_t sector) __z88dk_fastcall
{
  current_sector = sector;
}

void bios_setdma(uint16_t dma_addr) __z88dk_fastcall
{
#ifdef UNUSED
  printString("FUJI SETDMA 0x");
  printHex(dma_addr, 4, '0');
  printString("\r\n");
#endif /* UNUSED */
  dma_buffer = (uint8_t *) dma_addr;
}

void calc_block(uint16_t track, uint16_t sector,
                uint16_t *block_size, uint16_t *block_num, uint16_t *offset)
{
#ifdef UNUSED
  printString("FUJI TRK=");
  printDec(track, 0, 0);
  printString(" SEC=");
  printDec(sector, 0, 0);
#endif /* UNUSED */

  // First track is always 26x128
  if (current_dph.dpb->spt == TRACK_0_NUMSEC || track == 0) {
    *block_size = SD_SECTOR_SIZE;
    *block_num = (sector - 1) + track * current_dph.dpb->spt;
    *offset = 0;
  }
  else {
    *block_size = DD_SECTOR_SIZE;
    sector += (track - 1) * current_dph.dpb->spt;
    *block_num = sector / 4 + TRACK_0_NUMSEC;
    *offset = (sector % 4) * SD_SECTOR_SIZE;
  }

#ifdef UNUSED
  printString(" MSC=");
  printDec(sector % 4, 0, 0);
  printString(" BLK=");
  printDec(*block_num, 0, 0);
  printString(" SZ=");
  printDec(*block_size, 0, 0);
  printString(" OFF=");
  printDec(*offset, 0, 0);
  printString("\r\n");
#endif /* UNUSED */

  return;
}

uint8_t bios_read(void)
{
  uint16_t block_size, block_num, offset;


#ifdef UNUSED
#ifdef __SCCZ80
  printString("FUJI READ TRK=");
  printDec(current_track, 0, 0);
  printString(" SEC=");
  printDec(current_sector, 0, 0);
  printString("\r\n");
#else
  consolef("FUJI READ TRK=%d SEC=%d\n", current_track, current_sector);
#endif /* __SCCZ80 */
#endif /* UNUSED */

  calc_block(current_track, current_sector, &block_size, &block_num, &offset);

  if (last_block != block_num) {
#ifdef UNUSED
    printString("FUJI READ LAST=");
    printDec(last_block, 0, 0);
    printString(" REQ=");
    printDec(block_num, 0, 0);
    printString("\r\n");
#endif /* UNUSED */
    if (!fuji_bus_call(FUJI_DEVICEID_DISK + current_drive,
                       DISKCMD_READ, FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                       NATIVE_SPLIT_U32(block_num),
                       block_buffer, block_size))
      return 1;
    last_block = block_num;
  }

  memcpy(dma_buffer, &block_buffer[offset], SD_SECTOR_SIZE);
#ifdef UNUSED
  dumpHex(dma_buffer, SD_SECTOR_SIZE, offset);
#endif /* UNUSED */

  return 0;
}

uint8_t bios_write(uint8_t write_type) __z88dk_fastcall
{
  uint16_t block_size, block_num, offset;
  uint8_t *ptr;


  printString("FUJI WRITE\r\n");

  calc_block(current_track, current_sector, &block_size, &block_num, &offset);

  if (block_size != SD_SECTOR_SIZE && last_block != block_num) {
    if (!fuji_bus_call(FUJI_DEVICEID_DISK + current_drive,
                       DISKCMD_READ, FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
                       NATIVE_SPLIT_U32(block_num),
                       block_buffer, block_size))
      return 1;

    last_block = block_num;
    memcpy(&block_buffer[offset], dma_buffer, SD_SECTOR_SIZE);
    ptr = block_buffer;
  }
  else
    ptr = dma_buffer;

  return !fuji_bus_call(FUJI_DEVICEID_DISK + current_drive,
                        DISKCMD_WRITE, FUJI_FIELD_C1234 | FUJI_FIELD_DATA,
                        NATIVE_SPLIT_U32(block_num),
                        ptr, block_size);
}

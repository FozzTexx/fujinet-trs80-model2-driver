#include <stdint.h>

/**
 * Disk Parameter Block (DPB)
 * Fits perfectly into 15 bytes.
 */
struct CPM_DPB {
  uint16_t spt;              /* Number of 128-byte logical sectors per track */
  uint8_t  bsh;              /* Block shift factor (e.g., 3 = 1KB blocks, 4 = 2KB blocks) */
  uint8_t  blm;              /* Block mask (2^BSH - 1) */
  uint8_t  exm;              /* Extent mask */
  uint16_t dsm;              /* Disk size max (Total blocks on drive - 1) */
  uint16_t drm;              /* Directory max (Total directory entries - 1) */
  uint8_t  al0;              /* Directory allocation bitmask byte 0 */
  uint8_t  al1;              /* Directory allocation bitmask byte 1 */
  uint16_t cks;              /* Checksum vector size */
  uint16_t off;              /* Track offset (Reserved system tracks) */
};

/**
 * Directory Entry Header (FCB-compatible format)
 * Fits perfectly into 32 bytes.
 */
struct CPM_DirEntry {
  uint8_t  dr;               /* Drive code / user area (0-15 = user area, 0xE5 = deleted) */
  uint8_t  f[8];             /* File name (Padded with spaces) */
  uint8_t  t[3];             /* File extension (Padded with spaces) */
  uint8_t  ex;               /* Current extent index number */
  uint8_t  s1;               /* Reserved for BDOS internal use */
  uint8_t  s2;               /* High byte of extent count */
  uint8_t  rc;               /* Record count for current extent (0 to 128) */
  uint8_t  dm[16];           /* Disk map: Raw block indices allocated to this extent */
};

/**
 * Disk Parameter Header (DPH)
 * Fits perfectly into 16 bytes because pointers are 16-bit on Z80.
 */
struct CPM_DPH {
  const uint8_t *xlt;        /* Sector translation (skew) table pointer. NULL if none. */
  uint16_t scratch1;         /* BDOS scratchpad word 1 */
  uint16_t scratch2;         /* BDOS scratchpad word 2 */
  uint16_t scratch3;         /* BDOS scratchpad word 3 */

  union {
    uint8_t *raw_bytes;
    struct CPM_DirEntry *entries;
  } dirbuf;                  /* Shared 128-byte directory sector buffer pointer */

  const struct CPM_DPB *dpb; /* Associated Disk Parameter Block pointer */
  uint8_t *csv;              /* Directory checksum vector buffer pointer */
  uint8_t *alv;              /* Allocation vector buffer pointer */
};

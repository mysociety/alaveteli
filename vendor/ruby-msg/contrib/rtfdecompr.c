#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void decompress_rtf(FILE *srcf)
{
//	#define prebuf_len (sizeof(prebuf))
//	static unsigned char prebuf[] =

	// the window of decompressed bytes that can be referenced for copies.
	// moved to this rather than indexing directly into output for streaming.
	// circular buffer.
	// because we use single-function call approach, no need for copy.
	// if using libstream-3, i would have a few options. i would be part of
	// the filter interface, which doesn't care if it is reading or writing,
	// all it knows about is its input and output buffers. we can't just
	// flush some data to the output buffer in that scenario, so we would need
	// to keep the window around. we also can't guarantee availability of that
	// buffer. so, we would probably have a instance member which would be
	// this ->
	unsigned char buf[4096] =
		"{\\rtf1\\ansi\\mac\\deff0\\deftab720{\\fonttbl;}"
		"{\\f0\\fnil \\froman \\fswiss \\fmodern \\fscript "
		"\\fdecor MS Sans SerifSymbolArialTimes New RomanCourier"
		"{\\colortbl\\red0\\green0\\blue0\n\r\\par "
		"\\pard\\plain\\f0\\fs20\\b\\i\\u\\tab\\tx";

	#define BUF_MASK 4095		

	int wp = strlen((char *)buf);

	unsigned char *dst; // destination for uncompressed bytes
	int in = 0; // current position in src array
	int out = 0; // current position in dst array

	unsigned char hdr[16];
	int got;
	// get header fields (as defined in RTFLIB.H)
	got = fread(hdr, 1, 16, srcf);
	if (got != 16) {
		printf("Invalid compressed-RTF header\n");
		exit(1);
	}

	int compr_size = *(unsigned int *)(hdr);
	int uncompr_size = *(unsigned int *)(hdr + 4);
	int magic = *(unsigned int *)(hdr + 8);
	long crc32 = *(unsigned int *)(hdr + 12);

	unsigned char *x, *y;;
	unsigned char *src = malloc(compr_size - 12); // includes the 3 header fields
	y = src;
	x = src + compr_size - 12;
	got = fread(src, 1, compr_size - 12, srcf);
	if (got != compr_size - 12) {
		printf("compressed-RTF data size mismatch (%d != %d)\n", got, compr_size - 12);
		exit(1);
	}
	// shouldn't be any more than that
	got = fread(dst, 1, 16, srcf);
	if (got > 0) {
		printf("warning: data after the size\n");
	}

	// process the data
	if (magic == 0x414c454d) { // magic number that identifies the stream as a uncompressed stream
		dst = malloc(uncompr_size);
		memcpy(dst, src, uncompr_size);
	}
	else if (magic == 0x75465a4c) { // magic number that identifies the stream as a compressed stream
		out = 0; //strlen(prebuf);
		int dst_len;
		dst = malloc(dst_len = uncompr_size);

		int flagCount = 0;
		int flags = 0;
		while (out < dst_len && src < x) {
			// each flag byte flags 8 literals/references, 1 per bit
			flags = (flagCount++ % 8 == 0) ? *src++ : flags >> 1;
			if (flags & 1) { // each flag bit is 1 for reference, 0 for literal
				int rp = *src++;
				int l = *src++;
				//offset is a 12 byte number. 2^12 is 4096, so thats fine
				rp = (rp << 4) | (l >> 4); // the offset relative to block start
				l = (l & 0xf) + 2; // the number of bytes to copy
				int e = rp + l;
				while (rp < e)
					putchar(buf[wp++ & BUF_MASK] = buf[rp++ & BUF_MASK]);
			}
			else putchar(buf[wp++ & BUF_MASK] = *src++);
		}
	}
	else { // unknown magic number
		printf("Unknown compression type (magic number %04x)", magic);
	}

	free(y);
}

int main(int argc, char *argv[])
{
	FILE *file = fopen(argv[1], "rb");
	decompress_rtf(file);
	fclose(file);
}

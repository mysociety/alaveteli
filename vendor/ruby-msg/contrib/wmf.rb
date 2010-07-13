
# this file will be used later to enhance the msg conversion.

# doesn't really work very well....

def wmf_getdimensions wmf_data
	# check if we have a placeable metafile
	if wmf_data.unpack('L')[0] == 0x9ac6cdd7
		# do check sum test
		shorts = wmf_data.unpack 'S11'
		warn 'bad wmf header checksum' unless shorts.pop == shorts.inject(0) { |a, b| a ^ b }
		# determine dimensions
		left, top, right, bottom, twips_per_inch = wmf_data[6, 10].unpack 'S5'
		p [left, top, right, bottom, twips_per_inch]
		[right - left, bottom - top].map { |i| (i * 96.0 / twips_per_inch).round }
	else
		[nil, nil]
	end
end

=begin

some attachment stuff
rendering_position
object_type
attach_num
attach_method

rendering_position is around (1 << 32) - 1 if its inline

attach_method 1 for plain data?
attach_method 6 for embedded ole

display_name instead of reading the embedded ole type.


PR_RTF_IN_SYNC property is missing or set to FALSE.


Before reading from the uncompressed RTF stream, sort the message's attachment
table on the value of the PR_RENDERING_POSITION property. The attachments will
now be in order by how they appear in the message.

As your client scans through the RTF stream, check for the token "\objattph".
The character following the token is the place to put the next attachment from
the sorted table. Handle attachments that have set their PR_RENDERING_POSITION
property to -1 separately.

eg from rtf.

\b\f2\fs20{\object\objemb{\*\objclass PBrush}\objw1320\objh1274{\*\objdata
01050000 <- looks like standard header
02000000 <- not sure
07000000 <- this means length of following is 7. 
50427275736800 <- Pbrush\000 in hex
00000000 <- ?
00000000 <- ?
e0570000 <- this is 22496. length of the following in hex
this is the bitmap data, starting with BM....
424dde57000000000000360000002800000058000000550000000100180000000000a857000000
000000000000000000000000000000c8d0d4c8d0d4c8d0d4c8d0d4c8d0d4c8d0d4c8d0d4c8d0d4

---------------

tested 3 different embedded files:

1. excel embedded
   - "\002OlePres000"[40..-1] can be saved to '.wmf' and opened.
   - "\002OlePres001" similarly.
     much better looking image. strange
   - For the rtf serialization, it has the file contents as an
     ole, "d0cf11e" serialization, which i can't do yet. this can
     be extracted as a working .xls
     followed by a METAFILEPICT chunk, correspoding to one of the
     ole pres chunks.
     then the very same metafile chunk in the result bit.

2. pbrush embedded image
   - "\002OlePres000" wmf as above.
   - "\001Ole10Native" is a long followed by a plain old .bmp
   - Serialization:
     Basic header as before, then bitmap data follows, then the
     metafile chunk follows, though labeled PBrush again this time.
     the result chunk was corrupted

3. metafile embedded image
   - no presentation section, just a
   - "CONTENTS" section, which can be saved directly as a wmf.
     different header to the other 2 metafiles. it starts with
     9AC6CDD7, which is the Aldus placeable metafile header.
     (http://wvware.sourceforge.net/caolan/ora-wmf.html)
     you can decode the left, top, right, bottom, and then
     multiply by 96, and divide by the metafile unit converter thing
     to get pixel values.

the above ones were always the plain metafiles
word filetype (0 = memory, 1 = disk)
word headersize (always 9)
word version
thus leading to the
0100
0900
0003
pattern i usually see.

=end


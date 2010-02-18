#include <stdio.h>
#define bool int
#define false 0
#define true 1

// RTF/HTML functions
// --------------------
//
// Sometimes in MAPI, the PR_BODY_HTML property contains the HTML of a message.
// But more usually, the HTML is encoded inside the RTF body (which you get in the
// PR_RTF_COMPRESSED property). These routines concern the decoding of the HTML
// from this RTF body.
//
// An encoded htmlrtf file is a valid RTF document, but which contains additional
// html markup information in its comments, and sometimes contains the equivalent
// rtf markup outside the comments. Therefore, when it is displayed by a plain
// simple RTF reader, the html comments are ignored and only the rtf markup has
// effect. Typically, this rtf markup is not as rich as the html markup would have been.
// But for an html-aware reader (such as the code below), we can ignore all the
// rtf markup, and extract the html markup out of the comments, and get a valid
// html document.
//
// There are actually two kinds of html markup in comments. Most of them are
// prefixed by "\*\htmltagNNN", for some number NNN. But sometimes there's one
// prefixed by "\*\mhtmltagNNN" followed by "\*\htmltagNNN". In this case,
// the two are equivalent, but the m-tag is for a MIME Multipart/Mixed Message
// and contains tags that refer to content-ids (e.g. img src="cid:072344a7")
// while the normal tag just refers to a name (e.g. img src="fred.jpg")
// The code below keeps the m-tag and discards the normal tag.
// If there are any m-tags like this, then the message also contains an
// attachment with a PR_CONTENT_ID property e.g. "072344a7". Actually,
// sometimes the m-tag is e.g. img src="http://outlook/welcome.html" and the
// attachment has a PR_CONTENT_LOCATION "http://outlook/welcome.html" instead
// of a PR_CONTENT_ID.
//
// This code is experimental. It works on my own message archive, of about
// a thousand html-encoded messages, received in Outlook97 and Outlook2000
// and OutlookXP. But I can't guarantee that it will work on all rtf-encoded
// messages. Indeed, it used to be the case that people would simply stick
// {\fromhtml at the start of an html document, and } at the end, and send
// this as RTF. If someone did this, then it will almost work in my function
// but not quite. (Because I ignore \r and \n, and respect only \par. Thus,
// any linefeeds in the erroneous encoded-html will be ignored.)





// ISRTFHTML -- Given an uncompressed RTF body of the message, this
// function tells you whether it encodes some html.
// [in] (buf,*len) indicate the start and length of the uncompressed RTF body.
// [return-value] true or false, for whether it really does encode some html
bool isrtfhtml(const char *buf,unsigned int len)
{ // We look for the words "\fromhtml" somewhere in the file.
  // If the rtf encodes text rather than html, then instead
  // it will only find "\fromtext".
  const char *c;
  for (c=buf; c<buf+len; c++)
  { if (strncmp(c,"\\from",5)==0) return strncmp(c,"\\fromhtml",9)==0;
  }
  return false;
}




// DECODERTFHTML -- Given an uncompressed RTF body of the message,
// and assuming that it contains encoded-html, this function
// turns it onto regular html.
// [in] (buf,*len) indicate the start and length of the uncompressed RTF body.
// [out] the buffer is overwritten with the HTML version, null-terminated,
// and *len indicates the length of this HTML.
//
// Notes: (1) because of how the encoding works, the HTML version is necessarily
// shorter than the encoded version. That's why it's safe for the function to
// place the decoded html in the same buffer that formerly held the encoded stuff.
// (2) Some messages include characters \'XX, where XX is a hexedecimal number.
// This function simply converts this into ASCII. The conversion will only make
// sense if the right code-page is being used. I don't know how rtf specifies which
// code page it wants.
// (3) By experiment, I discovered that \pntext{..} and \liN and \fi-N are RTF
// markup that should be removed. There might be other RTF markup that should
// also be removed. But I don't know what else.
//
void decodertfhtml(char *buf,unsigned int *len)
{ // c -- pointer to where we're reading from
  // d -- pointer to where we're writing to. Invariant: d<c
  // max -- how far we can read from (i.e. to the end of the original rtf)
  // ignore_tag -- stores 'N': after \mhtmlN, we will ignore the subsequent \htmlN.
  char *c=buf, *max=buf+*len, *d=buf; int ignore_tag=-1;
  // First, we skip forwards to the first \htmltag.
  while (c<max && strncmp(c,"{\\*\\htmltag",11)!=0) c++;
  //
  // Now work through the document. Our plan is as follows:
  // * Ignore { and }. These are part of RTF markup.
  // * Ignore \htmlrtf...\htmlrtf0. This is how RTF keeps its equivalent markup separate from the html.
  // * Ignore \r and \n. The real carriage returns are stored in \par tags.
  // * Ignore \pntext{..} and \liN and \fi-N. These are RTF junk.
  // * Convert \par and \tab into \r\n and \t
  // * Convert \'XX into the ascii character indicated by the hex number XX
  // * Convert \{ and \} into { and }. This is how RTF escapes its curly braces.
  // * When we get \*\mhtmltagN, keep the tag, but ignore the subsequent \*\htmltagN
  // * When we get \*\htmltagN, keep the tag as long as it isn't subsequent to a \*\mhtmltagN
  // * All other text should be kept as it is.
  while (c<max)
  { if (*c=='{') c++;
    else if (*c=='}') c++;
    else if (strncmp(c,"\\*\\htmltag",10)==0)
    { c+=10; int tag=0; while (*c>='0' && *c<='9') {tag=tag*10+*c-'0'; c++;}
      if (*c==' ') c++;
      if (tag==ignore_tag) {while (c<max && *c!='}') c++; if (*c=='}') c++;}
      ignore_tag=-1;
    }
    else if (strncmp(c,"\\*\\mhtmltag",11)==0)
    { c+=11; int tag=0; while (*c>='0' && *c<='9') {tag=tag*10+*c-'0'; c++;}
      if (*c==' ') c++;
      ignore_tag=tag;
    }
    else if (strncmp(c,"\\par",4)==0) {strcpy(d,"\r\n"); d+=2; c+=4; if (*c==' ') c++;}
    else if (strncmp(c,"\\tab",4)==0) {strcpy(d,"   "); d+=3; c+=4; if (*c==' ') c++;}
    else if (strncmp(c,"\\li",3)==0)
    { c+=3; while (*c>='0' && *c<='9') c++; if (*c==' ') c++;
    }
    else if (strncmp(c,"\\fi-",4)==0)
    { c+=4; while (*c>='0' && *c<='9') c++; if (*c==' ') c++;
    }
    else if (strncmp(c,"\\'",2)==0)
    { unsigned int hi=c[2], lo=c[3];
      if (hi>='0' && hi<='9') hi-='0'; else if (hi>='A' && hi<='Z') hi-='A'; else if (hi>='a' && hi<='z') hi-='a';
      if (lo>='0' && lo<='9') lo-='0'; else if (lo>='A' && lo<='Z') lo-='A'; else if (lo>='a' && lo<='z') lo-='a';
      *((unsigned char*)d) = (unsigned char)(hi*16+lo);
      c+=4; d++;
    }
    else if (strncmp(c,"\\pntext",7)==0) {c+=7; while (c<max && *c!='}') c++;}
    else if (strncmp(c,"\\htmlrtf",8)==0)
    { c++; while (c<max && strncmp(c,"\\htmlrtf0",9)!=0) c++;
      if (c<max) c+=9; if (*c==' ') c++;
    }
    else if (*c=='\r' || *c=='\n') c++;
    else if (strncmp(c,"\\{",2)==0) {*d='{'; d++; c+=2;}
    else if (strncmp(c,"\\}",2)==0) {*d='}'; d++; c+=2;}
    else {*d=*c; c++; d++;}
  }
  *d=0; d++;
  *len = d-buf;
}


void main()
{
	unsigned char buf[1024*1024];
	int len = fread(buf, 1, 1024*1024, stdin);
	decodertfhtml(buf, &len);
	fwrite(buf, 1, len, stdout);
}

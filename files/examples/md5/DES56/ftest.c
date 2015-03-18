
/*
 * Fast DES evaluation & benchmarking for UNIX
 * Compares output of fencrypt()/fsetkey() with UNIX crypt()/encrypt()/setkey()
 * and measures speed using times().
 */

#include <stdio.h>
#include <stdlib.h>
#if USG
#include <sys/types.h>
#endif /*USG*/
#include <sys/param.h>	/* for HZ */
#include <sys/times.h>

#include <crypt.h>

#include "des56.h"

typedef struct {
	char b[8];
} chunk;

#ifdef CRAY
#  define  USG	1
#endif /*CRAY*/

#ifndef USG
#  define  USG	0
#endif	/*!USG*/

#if BSD >= 43 && defined(vax) && !defined(HZ)
#  define  HZ 100
#endif


char *
bprint(char b[64])
{
	static char s[17];
	register int i;

	for(i = 0; i < 64; i += 4)
	    sprintf(&s[i/4], "%1x", b[i]<<3 | b[i+1]<<2 | b[i+2]<<1 | b[i+3]);
	return(s);
}

char *
wprint(chunk *v)
{
	static char s[17];
	register int i;

	for(i = 0; i < 8; i++)
		sprintf(&s[2*i], "%02x", v->b[i] & 0xff);
	return(s);
}

void getv(char *s, chunk *v)
{
	register int i, t;

	if(s[0] == '0' && s[1] == 'x')
		s += 2;
	for(i = 0; i < 8; i++) {
		t = 0;
		if(*s >= '0' && *s <= '9') t = *s++ - '0';
		else if(*s >= 'a' && *s <= 'f') t = *s++ - 'a' + 10;
		else if(*s >= 'A' && *s <= 'F') t = *s++ - 'A' + 10;
		t <<= 4;
		if(*s >= '0' && *s <= '9') t |= *s++ - '0';
		else if(*s >= 'a' && *s <= 'f') t |= *s++ - 'a' + 10;
		else if(*s >= 'A' && *s <= 'F') t |= *s++ - 'A' + 10;
		v->b[i] = t;
		if(*s == '.') {
			s++;
			i = 4-1;
		}
	}
}

void expand(chunk *v, char bits[64])
{
	register unsigned int i;

	for(i = 0; i < 64; i++)
		bits[i] = (v->b[i/8] >> (7 - i%8)) & 1;
}


int
main(int argc, char *argv[])
{
	register int i;
	chunk key, olddata, newdata;
	char bkey[64], bdata[64];
	int decrypt = 0;
	keysched KS;

	if(argc < 2 || argv[1][0] == '-') {

    usage:
		printf("\
Usage: %s  key	[ -{ckCK} count ] [ data ... ]\n\
Demonstrate and/or time fast DES routines.\n\
``key'' and ``data'' are left-justified, 0-padded hex values <= 16 digits\n\
By default, encrypts & decrypts each 'data' block with both fastdes and\n\
crypt() library DES routines to show equality.\n\
-c N	encrypt N times using fast DES\n\
-k N	set-key N times using fast DES\n\
-C N	encrypt N times using library DES\n\
%s",
			argv[0],
			USG ? "" : "\
-K N	set-key N times using library DES\n");
		exit(1);
	}

	getv(argv[1], &key);
	fsetkey(key.b, &KS);
	expand(&key, bkey);
#if USG
	/* System V systems don't seem to have setkey, just crypt
	 * so we use that to set the key.
	 */
	for(i = 0; i < 8; i++)
		bdata[i] = (key.b[i] >> 1) | 0x80;
	bdata[8] = '\0';
	crypt((char *)bdata, "..");	/* Key, no salt */
#else /*!USG*/
	setkey(bkey);
#endif /*!USG*/
	printf("key\t%s\n", bprint(bkey));

	for(i = 2; i < argc; i++) {
	    if(argv[i][0] == '-') {
		int count, n;
		char c, *op;
		struct tms now, then;

		c = argv[i][1];
		op = &argv[i][2];
		if(*op == '\0')
			if((op = argv[++i]) == NULL)
				goto usage;
		count = atoi(op);
		if(count <= 0)
		    count = 1;
		n = count;
		expand(&olddata, bdata);
		times(&now);
		switch(c) {
		case 'c':
		    op = "fencrypt";
		    do fencrypt(newdata.b, 0, &KS); while(--n > 0); break;
		case 'k':
		    op = "fsetkey";
		    do fsetkey(key.b, &KS); while(--n > 0); break;

		case 'C':
		    op = "library encrypt";
		    do encrypt(bdata, decrypt); while(--n > 0); break;

		case 'K':
#if USG
		    printf("UNIX library has no setkey() function on this system\n");
		    continue;
#else /*!USG*/
		    op = "library setkey";
		    do setkey(bkey); while(--n > 0); break;
#endif /*!USG*/

		default:
		    printf("Unknown option -%c\n", c);
		    goto usage;
		}
		times(&then);
		n = then.tms_utime - now.tms_utime;
		printf("%d %s's in %0.2f seconds (%.2f us apiece)\n",
		    count, op, (float) n / HZ,
		    (1.0e6 * n / (HZ * count)));
	    } else {
		/* Demonstrate that it works for a particular data block.
		 * To compare with UNIX encrypt(), we must play its game.
		 * On BSD systems, encrypt(block, 1) is the inverse of (..., 0)
		 * but on USG systems the second parameter is ignored and
		 * encrypt(block, x) always encrypts.
		 */
		getv(argv[i], &olddata);
		newdata = olddata;

		printf("\tOriginal data\t\tEncrypted\t\t%s\n",
			USG ? "Encrypted again" : "Decrypted");

		printf("fastdes\t%s", wprint(&olddata));
		fencrypt(newdata.b, 0, &KS);
		printf("\t%s", wprint(&newdata));
		fencrypt(newdata.b, USG ? 0 : 1, &KS);
		printf("\t%s\n", wprint(&newdata));

		expand(&olddata, bdata);
		printf("UNIXdes\t%s", bprint(bdata));
		encrypt(bdata, 0);
		printf("\t%s", bprint(bdata));
		encrypt(bdata, USG ? 0 : 1);
		printf("\t%s\n", bprint(bdata));
	    }
	}
	exit(0);
}


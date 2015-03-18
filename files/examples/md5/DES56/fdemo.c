
/*
 * Fast DES evaluation & benchmarking, not dependent on UNIX
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "des56.h"


typedef struct {
	char b[8];
} chunk;

char *wprint(chunk *v)
{
	static char s[18];
	register int i;
	register char *p;

	p = s;
	for(i = 0; i < 8; i++) {
		sprintf(p, "%02x", v->b[i] & 0xff);
		p += 2;
		if(i == 4-1) *p++ = '.';
	}
	return(s);
}

void getv(char *s, chunk *v)
{
	register int i, t;

	if(s[0] == '0' && s[1] == 'x')
		s += 2; /* Ignore C-style 0x prefix */
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
		if(*s == '.' && i == 3) {
			s++;
		}
	}
}

struct demo {
	int  decrypt;
	char *key, *data;
	char *expect;
};

struct demo demos[] = {
   { 0, "00000000.00000000", "00000000.00000000", "8ca64de9.c1b123a7" },
   { 0, "11111111.11111111", "00000000.00000000", "82e13665.b4624df5" },
   { 0, "12486248.62486248", "f0e1d2c3.b4a59687", "f4682865.376f93ea" },
   { 1, "12486248.62486248", "f0e1d2c3.b4a59687", "df597e0f.84fd994f" },
   { 0, "1bac8107.6a39042d", "812801da.cbe98103", "d8883b2c.4a7c61dd" },
   { 1, "1bac8107.6a39042d", "d8883b2c.4a7c61dd", "812801da.cbe98103" },
   { 1, "fedcba98.76543210", "a68cdca9.0c9021f9", "00000000.00000000" },
   { 0, "eca86420.13579bdf", "01234567.89abcdef", "a8418a54.ff97a505" },
};


void fdemo(void)
{
	keysched KS;
	register struct demo *dp;
	chunk key, data;
	char *got;

	printf("\
Op(	 Key,	    Data to En/Decrypt) =      Computed     ?=	  Expected\n");
	for(dp = demos; dp < &demos[sizeof(demos)/sizeof(*demos)]; dp++) {
		getv(dp->key, &key);
		fsetkey(key.b, &KS);
		getv(dp->data, &data);
		fencrypt(data.b, dp->decrypt, &KS);
		got = wprint(&data);
		printf("%c(%s, %s) = %s %c %s\n",
			"ED"[dp->decrypt], dp->key, dp->data,
			got,
			strcmp(got, dp->expect) ? '!' : '=',
			dp->expect);
	}
}

int main(int argc, char *argv[])
{
	register int i;
	chunk key, olddata, newdata;
	int decrypt = 0;
	int first = 1;
	keysched KS;

	if(argc <= 1) {

    usage:
		printf("\
Usage: fdemo  key  [ -demo ] [ -{ck} N ] [ [-{ed}] data ... ]\n\
Demonstrate and/or time fast DES routines.\n\
``key'' and ``data'' are left-justified, 0-padded hex values <= 16 digits\n\
	optionally with a `.' at the 32-bit point\n\
-demo	tries a batch of values, compares fencrypt() with precomputed result\n\
-c N	encrypt N times using fast DES\n\
-k N	set-key N times using fast DES\n\
-e	encrypt following data value(s) (default)\n\
-d	decrypt following data value(s)\n");
		return(1);
	}


	for(i = 1; i < argc; i++) {
	    if(argv[i][0] == '-') {
		int count, n;
		char c, *op;

		/* Should use getopt but it might not be there */
		c = argv[i][1];
		if(c == 'e' || c == 'd') {
		    if(strcmp(argv[i], "-demo") == 0) {
			fdemo();
		    } else {
			decrypt = (c == 'd');
		    }
		    continue;
		}

		fsetkey(key.b, &KS);	/* Make sure it's done at least once */
		op = &argv[i][2];
		if(*op == '\0')
			if((op = argv[++i]) == NULL)
				goto usage;
		count = atoi(op);
		if(count <= 0) count = 1;
		n = count;
		printf("Starting ...<\007");
		fflush(stdout);
		switch(c) {
		case 'c':
		    op = "fencrypt";
		    do fencrypt(newdata.b, 0, &KS); while(--n > 0); break;
		case 'k':
		    op = "fsetkey";
		    do fsetkey(key.b, &KS); while(--n > 0); break;
		default:
		    printf("Unknown option -%c\n", c);
		    goto usage;
		}
		printf("\007> completed %d %s's\n", count, op);
	    } else if(first) {
		getv(argv[1], &key);
		fsetkey(key.b, &KS);
		printf("key\t%s\n", wprint(&key));
		first = 0;
	    } else {
		getv(argv[i], &olddata);
		newdata = olddata;

		printf("%s %s => ",
		    decrypt ? "decrypt" : "encrypt",
		    wprint(&olddata));
		fencrypt(newdata.b, decrypt, &KS);
		printf("%s %s => ",
		    !decrypt ? "decrypt" : "encrypt",
		    wprint(&newdata));
		fencrypt(newdata.b, !decrypt, &KS);
		printf("%s\n", wprint(&newdata));
	    }
	}
	return(0);
}

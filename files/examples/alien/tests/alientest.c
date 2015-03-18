
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifdef _WIN32
#include <windows.h>
#endif

#if defined(_WIN32) || defined(__CYGWIN__)
#define EXPORT(x) __declspec(dllexport) x
#else
#define EXPORT(x) x
#endif

/* some functions handy for testing */

EXPORT(void *) my_malloc(size_t size) {
  return malloc(size);
}

EXPORT(char *)my_strtok(char *token, const char *delim)
{
	return strtok(token, delim);
}

EXPORT(char *)my_strchr(const char *s, int c)
{
	return strchr(s, c);
}


EXPORT(double) my_sqrt(double a)
{
	return sqrt(a);
}

EXPORT(void) my_qsort(void *base, size_t num, size_t width, int(*compare)(const void*, const void*))
{
	qsort(base, num, width, compare);
}

EXPORT(int) my_compare(char *a, char *b)
{
        return *a - *b;
}

EXPORT(int *) _testfunc_ai8(int a[8])
{
	return a;
}

EXPORT(void) _testfunc_v(int a, int b, int *presult)
{
	*presult = a + b;
}

EXPORT(int) _testfunc_i_bhilfd(signed char b, short h, int i, long l, float f, double d)
{
  /*	printf("_testfunc_i_bhilfd got %d %d %d %ld %f %f\n",
	b, h, i, l, f, d);*/

	return (int)(b + h + i + l + f + d);
}

EXPORT(unsigned long) _testfunc_L_HIL(unsigned short h, unsigned int i, unsigned long l)
{
  return (unsigned long)(h + i + l);
}

EXPORT(float) _testfunc_f_bhilfd(signed char b, short h, int i, long l, float f, double d)
{
  /*	printf("_testfunc_f_bhilfd got %d %d %d %ld %f %f\n",
	b, h, i, l, f, d);*/

	return (float)(b + h + i + l + f + d);
}

EXPORT(double) _testfunc_d_bhilfd(signed char b, short h, int i, long l, float f, double d)
{
  /*	printf("_testfunc_d_bhilfd got %d %d %d %ld %f %f\n",
	b, h, i, l, f, d);*/

	return (double)(b + h + i + l + f + d);
}

EXPORT(char *) _testfunc_p_p(void *s)
{
  return (char *)s;
}

EXPORT(void *) _testfunc_c_p_p(int *argcp, char **argv)
{
	return argv[(*argcp)-1];
}

EXPORT(void *) get_strchr(void)
{
	return (void *)strchr;
}

EXPORT(char *) my_strdup(char *src)
{
	char *dst = (char *)malloc(strlen(src)+1);
	if (!dst)
		return NULL;
	strcpy(dst, src);
	return dst;
}

EXPORT(void)my_free(void *ptr)
{
	free(ptr);
}

#ifdef HAVE_WCHAR_H
EXPORT(wchar_t *) my_wcsdup(wchar_t *src)
{
	size_t len = wcslen(src);
	wchar_t *ptr = (wchar_t *)malloc((len + 1) * sizeof(wchar_t));
	if (ptr == NULL)
		return NULL;
	memcpy(ptr, src, (len+1) * sizeof(wchar_t));
	return ptr;
}

EXPORT(size_t) my_wcslen(wchar_t *src)
{
	return wcslen(src);
}
#endif

#ifndef _WIN32
# ifndef __stdcall
#  define __stdcall /* */
# endif
#endif

typedef struct {
	int (*c)(int, int);
	int (__stdcall *s)(int, int);
} FUNCS;

EXPORT(int) _testfunc_callfuncp(FUNCS *fp)
{
	fp->c(1, 2);
	fp->s(3, 4);
	return 0;
}

EXPORT(int) _testfunc_deref_pointer(int *pi)
{
	return *pi;
}

EXPORT(int) _testfunc_callback_i_if(int value, int (*func)(int))
{
	int sum = 0;
	while (value != 0) {
		sum += func(value);
		value /= 2;
	}
	return sum;
}

EXPORT(int) _testfunc_callback_with_pointer(int (*func)(int *))
{
	int table[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

	return (*func)(table);
}

typedef struct {
	char *name;
	char *value;
} SPAM;

typedef struct {
	char *name;
	int num_spams;
	SPAM *spams;
} EGG;

SPAM my_spams[2] = {
	{ "name1", "value1" },
	{ "name2", "value2" },
};

EGG my_eggs[1] = {
	{ "first egg", 1, my_spams }
};

EXPORT(int) getSPAMANDEGGS(EGG **eggs)
{
	*eggs = my_eggs;
	return 1;
}

typedef struct tagpoint {
	int x;
	int y;
} point;

EXPORT(int) _testfunc_byval(point in, point *pout)
{
	if (pout) {
		pout->x = in.x;
		pout->y = in.y;
	}
	return in.x + in.y;
}

EXPORT (int) an_integer = 42;

EXPORT(int) get_an_integer(void)
{
	return an_integer;
}

EXPORT(double)
integrate(double a, double b, double (*f)(double), long nstep)
{
	double x, sum=0.0, dx=(b-a)/(double)nstep;
	for(x=a+0.5*dx; (b-x)*(x-a)>0.0; x+=dx)
		sum += f(x);
	return sum/(double)nstep;
}

typedef struct {
	void (*initialize)(void *(*)(int), void(*)(void *));
} xxx_library;

static void _xxx_init(void *(*Xalloc)(int), void (*Xfree)(void *))
{
	void *ptr;
	
	printf("_xxx_init got %p %p\n", Xalloc, Xfree);
	printf("calling\n");
	ptr = Xalloc(32);
	Xfree(ptr);
	printf("calls done, ptr was %p\n", ptr);
}

xxx_library _xxx_lib = {
	_xxx_init
};

EXPORT(xxx_library) *library_get(void)
{
	return &_xxx_lib;
}

/********/
 
#ifndef _WIN32

typedef struct {
	long x;
	long y;
} POINT;

typedef struct {
	long left;
	long top;
	long right;
	long bottom;
} RECT;

#endif

EXPORT(int) PointInRect(RECT *prc, POINT pt)
{
	if (pt.x < prc->left)
		return 0;
	if (pt.x > prc->right)
		return 0;
	if (pt.y < prc->top)
		return 0;
	if (pt.y > prc->bottom)
		return 0;
	return 1;
}

typedef struct {
	short x;
	short y;
} S2H;

EXPORT(S2H) ret_2h_func(S2H inp)
{
	inp.x *= 2;
	inp.y *= 3;
	return inp;
}

typedef struct {
	int a, b, c, d, e, f, g, h;
} S8I;

EXPORT(S8I) ret_8i_func(S8I inp)
{
	inp.a *= 2;
	inp.b *= 3;
	inp.c *= 4;
	inp.d *= 5;
	inp.e *= 6;
	inp.f *= 7;
	inp.g *= 8;
	inp.h *= 9;
	return inp;
}

typedef struct {
	long left;
	long top;
	long right;
	long bottom;
} RECT1;

EXPORT(int) GetRectangle1(int flag, RECT1 *prect)
{
	if (flag == 0)
		return 0;
	prect->left = (int)flag;
	prect->top = (int)flag + 1;
	prect->right = (int)flag + 2;
	prect->bottom = (int)flag + 3;
	return 1;
}

typedef struct {
	short left;
	long top;
	short right;
	long bottom;
} RECT2;

EXPORT(int) GetRectangle2(int flag, RECT2 *prect)
{
	if (flag == 0)
		return 0;
	prect->left = (int)flag;
	prect->top = (int)flag + 1;
	prect->right = (int)flag + 2;
	prect->bottom = (int)flag + 3;
	return 1;
}


EXPORT(int) GetRectangle3(RECT2 *prect)
{
	prect->left *= 2;
	prect->top *= 2;
	prect->right *= 2;
	prect->bottom *= 2;
	return 1;
}

EXPORT(int) GetRectangle4(RECT2 prect)
{
        return prect.left + prect.top + prect.right + prect.bottom;
}

EXPORT(void) TwoOutArgs(int a, int *pi, int b, int *pj)
{
	*pi += a;
	*pj += b;
}

EXPORT(signed char) tf_b(signed char c) { return c/3; }
EXPORT(unsigned char) tf_B(unsigned char c) { return c/3; }
EXPORT(short) tf_h(short c) { return c/3; }
EXPORT(unsigned short) tf_H(unsigned short c) { return c/3; }
EXPORT(int) tf_i(int c) { return c/3; }
EXPORT(unsigned int) tf_I(unsigned int c) { return c/3; }
EXPORT(long) tf_l(long c) { return c/3; }
EXPORT(unsigned long) tf_L(unsigned long c) { return c/3; }
EXPORT(float) tf_f(float c) { return c/3; }
EXPORT(double) tf_d(double c) { return c/3; }

EXPORT(signed char) tf_bb(signed char x, signed char c) { return c/3; }
EXPORT(unsigned char) tf_bB(signed char x, unsigned char c) { return c/3; }
EXPORT(short) tf_bh(signed char x, short c) { return c/3; }
EXPORT(unsigned short) tf_bH(signed char x, unsigned short c) { return c/3; }
EXPORT(int) tf_bi(signed char x, int c) { return c/3; }
EXPORT(unsigned int) tf_bI(signed char x, unsigned int c) { return c/3; }
EXPORT(long) tf_bl(signed char x, long c) { return c/3; }
EXPORT(unsigned long) tf_bL(signed char x, unsigned long c) { return c/3; }
EXPORT(float) tf_bf(signed char x, float c) { return c/3; }
EXPORT(double) tf_bd(signed char x, double c) { return c/3; }
EXPORT(void) tv_i(int c) { return; }

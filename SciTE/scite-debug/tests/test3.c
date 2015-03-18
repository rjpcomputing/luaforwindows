// build@ gcc -g test3.c -o test3
#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int a,b;
} A;

typedef struct {
    float x;
    A* y;
} B;


void three(int i)
{
    printf("three %d\n",i);
}

void two(int i)
{
    A a = {10,20};
    B b;
    b.x = 2.3f;
    b.y = &a;
    int val = b.y->a;	
    three(i);
    printf("i = %d\n",i);
}

void one(int i)
{
    int k,j;
    two(i);
    switch(i) {
        case 1:  k = 10; break;
        case 2: k = 44; break;
        case 3: k = 55; break;
        default: k = 10;
    }
    j = 1;
    j = 2;
    j = 3;
}

int main(int argc, char** argv)
{
    one(2);
    return 0;
}

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define printstr(ptr, length)                   \
    do {                                        \
        asm volatile(                           \
            "add a7, x0, 0x40;"                 \
            "add a0, x0, 0x1;" /* stdout */     \
            "add a1, x0, %0;"                   \
            "mv a2, %1;" /* length character */ \
            "ecall;"                            \
            :                                   \
            : "r"(ptr), "r"(length)             \
            : "a0", "a1", "a2", "a7");          \
    } while (0)

#define TEST_OUTPUT(msg, length) printstr(msg, length)

#define TEST_LOGGER(msg)                     \
    {                                        \
        char _msg[] = msg;                   \
        TEST_OUTPUT(_msg, sizeof(_msg) - 1); \
    }

extern uint64_t get_cycles(void);
extern uint64_t get_instret(void);


/* Software division for RV32I (no M extension) */
static unsigned long udiv(unsigned long dividend, unsigned long divisor)
{
    if (divisor == 0)
        return 0;

    unsigned long quotient = 0;
    unsigned long remainder = 0;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= (1UL << i);
        }
    }

    return quotient;
}

static unsigned long umod(unsigned long dividend, unsigned long divisor)
{
    if (divisor == 0)
        return 0;

    unsigned long remainder = 0;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if (remainder >= divisor) {
            remainder -= divisor;
        }
    }

    return remainder;
}

/* Software multiplication for RV32I (no M extension) */
static uint32_t umul(uint32_t a, uint32_t b)
{
    uint32_t result = 0;
    while (b) {
        if (b & 1)
            result += a;
        a <<= 1;
        b >>= 1;
    }
    return result;
}

/* Provide __mulsi3 for GCC */
uint32_t __mulsi3(uint32_t a, uint32_t b)
{
    return umul(a, b);
}

/* Simple integer to hex string conversion */
static void print_hex(unsigned long val)
{
    char buf[20];
    char *p = buf + sizeof(buf) - 1;
    *p = '\n';
    p--;

    if (val == 0) {
        *p = '0';
        p--;
    } else {
        while (val > 0) {
            int digit = val & 0xf;
            *p = (digit < 10) ? ('0' + digit) : ('a' + digit - 10);
            p--;
            val >>= 4;
        }
    }

    p++;
    printstr(p, (buf + sizeof(buf) - p));
}

/* Simple integer to decimal string conversion */
void print_dec(unsigned long val)
{
    char buf[20];
    char *p = buf + sizeof(buf) - 1;
    // *p = '\n';
    // p--;

    if (val == 0) {
        *p = '0';
        p--;
    } else {
        while (val > 0) {
            *p = '0' + umod(val, 10);
            p--;
            val = udiv(val, 10);
        }
    }

    p++;
    printstr(p, (buf + sizeof(buf) - p));
}


void print_char(char c)
{
    char buf[1];
    buf[0] = c;

    printstr(buf, 1);
}

/* ============= Declaration ============= */

extern uint32_t hanoi_asm();

/* ============= Hanoi  ============= */

typedef struct {
    int v[3];   
    int top;
} Stack;

static void push(Stack *s, int x) { s->v[++s->top] = x; }
static int  pop (Stack *s)        { return s->v[s->top--]; }
static int  peek(const Stack *s)  { return (s->top >= 0) ? s->v[s->top] : 0; } 


static void move_between(Stack *a, Stack *b, char la, char lb) {
    int ta = peek(a), tb = peek(b);
    int x;
    const char A = 'A';
    const char B = 'B';

    if (ta == 0) {                      
        x = pop(b); push(a, x);
    } else if (tb == 0) {              
        x = pop(a); push(b, x);
    } else if (ta < tb) {               
        x = pop(a); push(b, x);
    } else {                           
        x = pop(b); push(a, x);
    }
        TEST_LOGGER("Move Disk ");
        print_dec(x);
        TEST_LOGGER(" from ");
        print_char(la);
        TEST_LOGGER(" to ");
        print_char(lb);
        TEST_LOGGER("\n");
}

void hanoi_iter(int n) {
    Stack A = {.top = -1}, B = {.top = -1}, C = {.top = -1};
    for (int d = n; d >= 1; --d) push(&A, d);

    const int total = (1 << n) - 1;                
    int r = 0;                        

    for (int step = 0; step < total; ++step) {
        if (r == 0)      move_between(&A, &C, 'A', 'C');
        else if (r == 1) move_between(&A, &B, 'A', 'B');
        else             move_between(&B, &C, 'B', 'C');

        ++r;
        if (r == 3) r = 0;
    }
}


int main(void)
{
    uint64_t start_cycles, end_cycles, cycles_elapsed;
    uint64_t start_instret, end_instret, instret_elapsed;

    TEST_LOGGER("\n=== hanoi Tests Start ===\n\n");

    TEST_LOGGER("\n=== Assembly Tests ===\n\n");
    start_cycles = get_cycles();
    start_instret = get_instret();

    hanoi_asm();

    end_cycles = get_cycles();
    end_instret = get_instret();
    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("\n");
    TEST_LOGGER("Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("\n");
    TEST_LOGGER("Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");


    TEST_LOGGER("\n=== C Tests ===\n\n");

    start_cycles = get_cycles();
    start_instret = get_instret();

    hanoi_iter(3);

    end_cycles = get_cycles();
    end_instret = get_instret();
    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("\n");
    TEST_LOGGER("Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("\n");
    TEST_LOGGER("Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    return 0;
}
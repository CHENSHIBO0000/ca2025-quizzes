#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static inline void write_str_syscall(int fd, const char *ptr, long len) {
    register long a0 asm("a0") = fd;
    register const char *a1 asm("a1") = ptr;
    register long a2 asm("a2") = len;
    register long a7 asm("a7") = 64;   // system_write

    asm volatile("ecall"
                 : "+r"(a0)              
                 : "r"(a1), "r"(a2), "r"(a7)
                 : "memory", "cc");      
}

#define printstr(ptr, length) write_str_syscall(1, (ptr), (length))

#define TEST_OUTPUT(msg, length) printstr((msg), (length))

#define TEST_LOGGER(msg)                          \
do {                                              \
    static const char _s_[] = msg;                \
    TEST_OUTPUT(_s_, (long)(sizeof(_s_) - 1));    \
} while (0)

extern uint64_t get_cycles(void);
extern uint64_t get_instret(void);

/* Bare metal memcpy implementation */
void *memcpy(void *dest, const void *src, size_t n)
{
    uint8_t *d = (uint8_t *) dest;
    const uint8_t *s = (const uint8_t *) src;
    while (n--)
        *d++ = *s++;
    return dest;
}


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


/* ============= rsqrt  ============= */

static int clz(uint32_t x){
    if(!x) return 32;
    int n = 0;
    if((x & 0xFFFF0000) == 0) { n += 16; x <<= 16; }
    if((x & 0xFF000000) == 0) { n += 8; x <<= 8; }
    if((x & 0xF0000000) == 0) { n += 4; x <<= 4; }
    if((x & 0xC0000000) == 0) { n += 2; x <<= 2; }
    if((x & 0x80000000) == 0) { n += 1; }
    return n;
}

static uint64_t mul32(uint32_t a, uint32_t b)
{
    uint32_t lo = 0;
    uint32_t hi = 0;

    for (int i = 0; i < 32; i++) {
        if (b & (1U << i)) {
            uint32_t part_lo = a << i;
            uint32_t part_hi = (i == 0) ? 0 : (a >> (32 - i));
            lo += part_lo;

            if (lo < part_lo)
                hi++;

            hi += part_hi;
        }
    }

    return ((uint64_t)hi << 32) | lo;
}


static inline void mul32_lohi(uint32_t a, uint32_t b,
                              uint32_t *hi, uint32_t *lo)
{
    uint32_t L = 0, H = 0;
    for (int i = 0; i < 32; i++) {
        if (b & (1u << i)) {
            uint32_t part_lo = a << i;
            uint32_t part_hi = (i == 0) ? 0 : (a >> (32 - i));

            uint32_t oldL = L;
            L += part_lo;
            if (L < oldL) H++;

            H += part_hi;
        }
    }
    *hi = H; *lo = L;
}


static inline uint32_t shr64_lo32(uint32_t hi, uint32_t lo, uint32_t s)
{
    if (s == 0) return lo;
    return (lo >> s) | (hi << (32 - s));
}

static const uint32_t rsqrt_table[32] = {
    65536, 46341, 32768, 23170, 16384,
    11585, 8192, 5793, 4096, 2896,
    2048, 1448, 1024, 724, 512,
    362, 256, 181, 128, 90,
    64, 45, 32, 23, 16,
    11, 8, 6, 4, 3,
    2, 1
};

uint32_t rsqrt(uint32_t x)
{
    if (x == 0) return 0xFFFFFFFF;
    if (x == 1) return 65536;
    
    int exp = 31 - clz(x);
    // print_dec(exp);
    // TEST_LOGGER("\n");

    uint32_t y = rsqrt_table[exp];

    // Linear interpolation
    if(x > (1u << exp)){
        uint32_t y_next = (exp < 31) ? rsqrt_table[exp + 1] : 0;
        uint32_t delta = y - y_next;
        uint64_t numer = ((uint64_t)(x - (1u << exp)) << 16);
        uint32_t frac = (uint32_t)(numer >> exp);
        y = y - (uint32_t)((mul32(delta, frac)) >> 16);
    }

    // Newton-Raphson iterations
    for(int iter = 0; iter < 2; iter++) {
        uint64_t y_sq = mul32(y, y);
        uint32_t y2 = (uint32_t)(y_sq >> 16);
        uint64_t xy2 = (uint64_t)mul32(x, y2);
        uint64_t factor_num = (3u << 16);
        factor_num = (xy2 >= factor_num) ? 0 : (factor_num - xy2);
        uint32_t factor = (uint32_t)(factor_num >> 1);
        y = (uint32_t)((mul32(y, factor)) >> 16);
    }
    // print_dec(y);
    return y;
}


/* ============= Test  ============= */

void test_rsqrt(void)
{
    const uint32_t test_vals[] = {
        1, 2, 3, 4, 5, 8, 10, 16, 31, 32,
        64, 100, 255, 256, 512, 1000, 4096,
        65536, 100000
    };

    const uint32_t ref_vals[] = {
        65536, 46341, 37837, 32768, 29309, 23170, 20724, 16384, 11771, 11585,
        8192, 6554, 4104, 4096, 2896, 2072, 1024,
        256, 207
    };

    const int N = sizeof(test_vals)/sizeof(test_vals[0]);

    uint64_t total_abs_err = 0;
    uint64_t total_rel_bp  = 0;  
    uint32_t worst_x_abs = 0, worst_abs = 0;
    uint32_t worst_rel_bp = 0;

    TEST_LOGGER("\n--- rsqrt Test (integer) ---\n");

    for (int i = 0; i < N; i++) {
        uint32_t x    = test_vals[i];
        uint32_t y    = rsqrt(x);                 
        uint32_t ref  = ref_vals[i];    

        uint32_t abs_err = (y >= ref) ? (y - ref) : (ref - y);


        uint32_t rel_bp = udiv(abs_err * 10000u + (ref >> 1), ref);

        total_abs_err += abs_err;
        total_rel_bp  += rel_bp;
        if (abs_err > worst_abs)   { worst_abs = abs_err; worst_x_abs = x; }
        if (rel_bp  > worst_rel_bp){ worst_rel_bp = rel_bp; }

        TEST_LOGGER("x=");
        print_dec(x);
        TEST_LOGGER(" rsqrt=");
        print_dec(y);
        TEST_LOGGER(" ref=");
        print_dec(ref);
        TEST_LOGGER(" abs=");
        print_dec(abs_err);
        TEST_LOGGER(" rel=");
        print_dec(udiv(rel_bp , 100));
        TEST_LOGGER(".");
        print_dec(umod(rel_bp , 100));
        TEST_LOGGER("\n");
    }

    uint32_t avg_abs = (uint32_t)(udiv(total_abs_err , N));
    uint32_t avg_bp  = (uint32_t)(udiv(total_rel_bp  , N));

    TEST_LOGGER("\n--- Summary ---\n");
    TEST_LOGGER("Avg abs err: ");
    print_dec(avg_abs);
    TEST_LOGGER("\nAvg rel err: ");
    print_dec(udiv(avg_bp , 100));
    TEST_LOGGER(".");
    print_dec(umod(avg_bp , 100));
    TEST_LOGGER("\n");

    TEST_LOGGER("Worst abs err: ");
    print_dec(worst_abs);
    TEST_LOGGER(" (x=");
    print_dec(worst_x_abs);
    TEST_LOGGER(")\n");

    TEST_LOGGER("Worst rel err: ");
    print_dec(udiv(worst_rel_bp , 100));
    TEST_LOGGER(".");
    print_dec(umod(worst_rel_bp , 100));
    TEST_LOGGER("\n");
}


int main(void)
{

  uint64_t start_cycles, end_cycles, cycles_elapsed;
    uint64_t start_instret, end_instret, instret_elapsed;

    TEST_LOGGER("\n=== rsqrt Test Start ===\n");

    start_cycles = get_cycles();
    start_instret = get_instret();

    test_rsqrt();   

    end_cycles = get_cycles();
    end_instret = get_instret();

    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("\nCycles: ");
    print_dec((unsigned long)cycles_elapsed);
    TEST_LOGGER("\nInstret: ");
    print_dec((unsigned long)instret_elapsed);
    TEST_LOGGER("\n");

    return 0;
}
int hammingDistance(uint32_t x, uint32_t y) {
    uint32_t diff = x ^ y;
    int hamming_count = 1;

    // Shift out the leading zeros first
    uint32_t leading_zeros = clz(diff);

    if(diff==0)
        return 0;

    diff <<= leading_zeros;  

    // Count remaining '1's
    for (int i = 0; i < 31 - leading_zeros; i++) {
        diff <<= 1;
        if (diff & 0x80000000)
            hamming_count++;
        if(!diff)
            break;
    }
    

    return hamming_count;
}

static inline unsigned clz(uint32_t x)
{
    int n = 32, c = 16;
    do {
        uint32_t y = x >> c;
        if (y) {
            n -= c;
            x = y;
        }
        c >>= 1;
    } while (c);
    return n - x;
}
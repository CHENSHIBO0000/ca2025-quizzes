int hammingDistance(uint32_t x, uint32_t y) {
    uint32_t diff = x ^ y;
    int hamming_count = 0;

    if(diff==0)
        return 0; 

    // Count remaining '1's
    for (int i = 0; i < 32 ; i++) {
        diff <<= 1;
        if (diff & 0x80000000)
            hamming_count++;
        if(!diff)
            break;
    }
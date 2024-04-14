typedef unsigned int uint32_t;
typedef unsigned char uint8_t;

#define OUT_ADDR ((uint8_t *)0x20)

void main() {
    uint32_t val = 1;

    for (uint32_t i = 1; i < 6; i++) {
        val *= i;
        *(volatile uint32_t *)OUT_ADDR = val;
    }
}

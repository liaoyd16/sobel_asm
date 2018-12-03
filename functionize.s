#低16位，a0.r3 = addr.r3 << 1
#PG: a0.pg = 1

#低16位，a1.r3 = addr.r3 << 1  +1
#PG: a1.pg = 1

(r4_cam=1, r4_vga=4, r3_start=0101, bias=0)

#低16位，a0.r3 = (addr.r3 - 0x8000) << 1 = addr.r3 << 1
#PG = a0.r4 = 2

#低16位，a1.r3 = (addr.r3 - 8000) << 1 + 1 = addr.r3 << 1 + 1
#PG = a1.r4 = 2

(r4_cam=2, r4_vga=4, r3_start=8101, bias=8000)

#低16位，a0.r3 = addr.r3 << 1
#PG = a0.r4 = 3

#低16位，a1.r3 = (addr.r3 + 8000) << 1 + 1 = addr.r3 << 1 + 1
#PG = a1.r4 = 3

(r4_cam=3, r4_vga=5, r3_start=0101, bias=0)
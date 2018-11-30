; #CAM_SGN := 0x0BF04
; #BIAS_CAM = 0x10000，各个像素的r/g/b取值为[0-64)
; #BIAS_VGA = 0x40000，各个像素的r/g/b取值为[0-8)
; #W := 512?
; #H := ?
; #R3_STORE := 0x80000, [8, 0]
; #R4_STORE := 0x80001, [8, 1]

arith:
; #grey过程
; #操作区域：CAM内存
; #[r4 r3]为地址，初始地址为[0x1 0x0]
; #在计算过程中间变化，需要循环体保存到 R3_STORE...
; #变量：rgb:r2
; #临时变量：r0, r1
grey:
    li r3 0x0
    li r4 0x1
; #计算(w, h)的灰度和: 
grey_calc:
    ; #rgb = MEM[addr]
    excpg r4
    lw r3 r2 0x0
    excpg r4

    ; #MEM[R4_STORE] = r4
    ; #MEM[R3_STORE] = r3
    li r1 0x8
    li r0 0x0
    excpg r1
    sw r0 r3 0x0
    li r0 0x1
    sw r0 r4 0x0

    ; #blue: 0...011111, r3 = 0...011111 => r2
    ; #green: 0000011111100000, r3 = 00000111110....0 => r1
    ; #red: 111110...0, r3 = 111110...0 => r0
    ; #r2:rgb = r5+g5+b5

    addiu3 r2 r1 0x0
    addiu3 r2 r0 0x0
    li r3 0x1f
    and r2 r3
    sll r3 0x6
    and r1 r3
    sll r3 0x5
    and r0 r3

    srl r0 0x0
    srl r0 0x3
    srl r1 0x6

    addu r2 r2 r0
    addu r2 r2 r1

    ; #r4 = MEM[R4_STORE]
    ; #r3 = MEM[R3_STORE]
    li r1 0x8
    excpg r1
    li r0 0x0
    lw r0 r3 0x0
    li r0 0x1
    lw r0 r4 0x0

    ; #MEM[[r4 r3]]=r2
    excpg r4
    sw r3 r2 0x0
    excpg r4

    ; #r3 r4 更新
    addiu r3 0x1
    cmpi r3 0x0
    btnez cont
    nop
addr4:
    ; #r4 == 4?
    addiu r4 0x1
    cmpi r4 0x4
    bteqz sobel_zone1
cont:
    b grey_calc
    nop



; #sobel-write过程
; #暂时只提取竖线
; #操作区域：CAM内存
; #a0 = [r4 r3]为地址
; #r0, r1, r5临时变量

;;;; #zone 1
sobel_zone1:
    ; #init low_addr
    li r3 0x1
    sll r3 0x0
    addiu r3 0x1

;; #calc
sobel_zone1_loop:
; #a0: CAM偶数像素
cam_zone1_a0:
    ; #低16位，a0.r3 = addr.r3 << 1
    ; #PG: a0.pg = 1
    li r4 0x1
    excpg r4
    sll r3 0x1

    ; #r2为累加器
    li r2 0x0

    ; #a0 - 0x201
    li r0 0x2
    sll r0 0x0
    addiu r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 0x201
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a0 - 0x1ff
    addiu r0 0xfe
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 0x1ff
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a0 - 1
    li r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 1
    li r0 0x1
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
; #let r2 > 0: 检查最高位
    li r0 0x80
    sll r0 0x0
    and r0 r2
    cmpi r0 0x0
    bteqz cont_zone1_a0
    nop
; #取相反数：按位取反加一
reverse_zone1_a0:
    li r0 0x0
    addiu r0 0xff
    subu r0 r2 r2
    addiu r2 0x1
; #得到的r2至多为7位(128)，而存到VGA中最多为(16)，
; #除以4 v / 除以2，高出部分做clipping
; #r2 => r1.r/g/b
cont_zone1_a0:
    addiu r2 0x8
    sra r2 0x4
    li r1 0x0
    sll r2 0x5
    addu r1 r2 r1
    srl r2 0x3
    addu r1 r2 r1
    srl 0x3
    addu r1 r2 r1
; #write back: 
    ; #恢复[r4 r3]
    sra r3 0x1
    li r4 0x4
    ; #写入内存: addr
    excpg r4
    sw r3 r1 0x0

; #a1: CAM像素奇数像素
cam_zone1_a1:
    ; #低16位，a1.r3 = addr.r3 << 1  +1
    ; #PG: a1.pg = 1
    li r4 0x1
    excpg r4
    sll r3 0x1
    addiu r3 0x1

    ; #r2为累加器
    li r2 0x0

    ; #a1 - 0x201
    li r0 0x2
    sll r0 0x0
    addiu r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 0x201
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a1 - 0x1ff
    addiu r0 0xfe
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 0x1ff
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a1 - 1
    li r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 1
    li r0 0x1
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
; #let r2 > 0: 检查最高位
    li r0 0x80
    sll r0 0x0
    and r0 r2
    cmpi r0 0x0
    bteqz cont_zone1_a0
    nop
; #取相反数：按位取反加一
reverse_zone1_a1:
    li r0 0x0
    addiu r0 0xff
    subu r0 r2 r2
    addiu r2 0x1
; #得到的r2至多为7位(128)，而存到VGA中最多为(16)，
; #除以4 v / 除以2，高出部分做clipping
; #r2 => r1.r/g/b
cont_zone1_a1:
    addiu r2 0x8
    sra r2 0x4
    li r1 0x0
    sll r2 0x5
    addu r1 r2 r1
    srl r2 0x3
    addu r1 r2 r1
    srl 0x3
    addu r1 r2 r1
; #write back: 
    ; 恢复[r4 r3]
    addiu r3 0xff
    sra r3 0x1
    li r4 0x4
    ; 写入内存: addr
    excpg r4
    lw r3 r2 0x0
    sll r2 0x0
    addu r1 r2 r1
    sw r3 r1 0x0

;; #jump
    ; #r5: mask
    li r5 0xff
    addiu r3 0x2
    ; #r5 = r5 and r3
    and r5 r3
    cmpi r5 0x0
    bteqz add1_zone1
    nop
; #不换行
minus1_zone1:
    addiu r3 0xff
    b sobel_zone1_loop
; #换行：从一行的最后调到下一行首个像素
add1_zone1:
    addiu r3 0x1
; #判断：[r4 r3] [4 7f01]
    li r5 0x7f
    sll r5 0x0
    addiu r5 0x1
    cmp r3 r5
    btnez sobel_zone1_loop
    nop
    b sobel_zone2
    nop



;;;; #zone 2
sobel_zone2:
    ; #init low_addr
    li r3 0x81
    sll r3 0x0
    addiu r3 0x1

;; #calc
sobel_zone2_loop:
; #a0: CAM偶数像素
cam_zone2_a0:
    ; #低16位，a0.r3 = (addr.r3 - 0x8000) << 1 = addr.r3 << 1
    ; #PG = a0.r4 = 2
    li r4 0x2
    excpg r4
    sll r3 0x1

    ; #r2为累加器
    li r2 0x0

    ; #a0 - 0x201
    li r0 0x2
    sll r0 0x0
    addiu r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 0x201
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a0 - 0x1ff
    addiu r0 0xfe
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 0x1ff
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a0 - 1
    li r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 1
    li r0 0x1
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
; #let r2 > 0: 检查最高位
    li r0 0x80
    sll r0 0x0
    and r0 r2
    cmpi r0 0x0
    bteqz cont_zone2_a0
    nop
; #取相反数：按位取反加一
reverse_zone2_a0:
    li r0 0x0
    addiu r0 0xff
    subu r0 r2 r2
    addiu r2 0x1
; #得到的r2至多为7位(128)，而存到VGA中最多为(16)，
; #除以4 v / 除以2，高出部分做clipping
; #r2 => r1.r/g/b
cont_zone2_a0:
    addiu r2 0x8
    sra r2 0x4
    li r1 0x0
    sll r2 0x5
    addu r1 r2 r1
    srl r2 0x3
    addu r1 r2 r1
    srl 0x3
    addu r1 r2 r1
; #write back: 
    ; #恢复[r4 r3]
    sra r3 0x1
    addiu r0 0x80
    sll r0 0x0
    addu r3 r0 r3
    li r4 0x4
    ; #写入内存: addr
    excpg r4
    sw r3 r1 0x0

; #a1: CAM像素奇数像素
cam_zone2_a1:
    ; #低16位，a1.r3 = (addr.r3 + 8000) << 1 + 1 = addr.r3 << 1 + 1
    ; #PG = a1.r4 = 2
    li r4 0x2
    excpg r4
    sll r3 0x1
    addiu r3 0x1

    ; #r2为累加器
    li r2 0x0

    ; #a1 - 0x201
    li r0 0x2
    sll r0 0x0
    addiu r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 0x201
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a1 - 0x1ff
    addiu r0 0xfe
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 0x1ff
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a1 - 1
    li r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 1
    li r0 0x1
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
; #let r2 > 0: 检查最高位
    li r0 0x80
    sll r0 0x0
    and r0 r2
    cmpi r0 0x0
    bteqz cont_zone2_a0
    nop
; #取相反数：按位取反加一
reverse_zone2_a1:
    li r0 0x0
    addiu r0 0xff
    subu r0 r2 r2
    addiu r2 0x1
; #得到的r2至多为7位(128)，而存到VGA中最多为(16)，
; #除以4 v / 除以2，高出部分做clipping
; #r2 => r1.r/g/b
cont_zone2_a1:
    addiu r2 0x8
    sra r2 0x4
    li r1 0x0
    sll r2 0x5
    addu r1 r2 r1
    srl r2 0x3
    addu r1 r2 r1
    srl 0x3
    addu r1 r2 r1
; #write back: 
    ; #恢复[r4 r3]
    addiu r3 0xff
    sra r3 0x1
    li r0 0x80
    sll r0 0x0
    addu r0 r3 r3
    li r4 0x4
    ; #读出之前偶数像素rgb到r2
    ; #r2 + r1 写入内存: addr
    excpg r4
    lw r3 r2 0x0
    sll r2 0x0
    addu r1 r2 r1
    sw r3 r1 0x0

;; #jump
    ; #r5: mask 0x00ff
    li r5 0xff
    addiu r3 0x2
    ; #r5 = r5 and r3
    and r5 r3
    cmpi r5 0x0
    bteqz add1_zone2
    nop
; #不换行
minus1_zone2:
    addiu r3 0xff
    b sobel_zone2_loop
; #换行：从一行的最后调到下一行首个像素
add1_zone2:
    addiu r3 0x1
; #判断：[r4 r3] [4 ff01]
    li r5 0xff
    sll r5 0x0
    addiu r5 0x1
    cmp r3 r5
    btnez sobel_zone2_loop
    nop
    b sobel_zone3
    nop



;;;; #zone 3
sobel_zone3:
    ; #init low_addr
    li r3 0x1
    sll r3 0x0
    addiu r3 0x1

;; #calc
sobel_zone3_loop:
; #a0: CAM偶数像素
cam_zone3_a0:
    ; #低16位，a0.r3 = addr.r3 << 1
    ; #PG = a0.r4 = 3
    li r4 0x3
    excpg r4
    sll r3 0x1

    ; #r2为累加器
    li r2 0x0

    ; #a0 - 0x201
    li r0 0x2
    sll r0 0x0
    addiu r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 0x201
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a0 - 0x1ff
    addiu r0 0xfe
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 0x1ff
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a0 - 1
    li r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a0 + 1
    li r0 0x1
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
; #let r2 > 0: 检查最高位
    li r0 0x80
    sll r0 0x0
    and r0 r2
    cmpi r0 0x0
    bteqz cont_zone3_a0
    nop
; #取相反数：按位取反加一
reverse_zone3_a0:
    li r0 0x0
    addiu r0 0xff
    subu r0 r2 r2
    addiu r2 0x1
; #得到的r2至多为7位(128)，而存到VGA中最多为(16)，
; #除以4 v / 除以2，高出部分做clipping
; #r2 => r1.r/g/b
cont_zone3_a0:
    addiu r2 0x8
    sra r2 0x4
    li r1 0x0
    sll r2 0x5
    addu r1 r2 r1
    srl r2 0x3
    addu r1 r2 r1
    srl 0x3
    addu r1 r2 r1
; #write back: 
    ; #恢复[r4 r3]
    ; #addr.r3 = a0.r3 >> 1
    sra r3 0x1
    li r4 0x5
    ; #写入内存: addr
    excpg r4
    sw r3 r1 0x0

; #a1: CAM像素奇数像素
cam_zone3_a1:
    ; #低16位，a1.r3 = (addr.r3 + 8000) << 1 + 1 = addr.r3 << 1 + 1
    ; #PG = a1.r4 = 3
    li r4 0x3
    excpg r4
    sll r3 0x1
    addiu r3 0x1

    ; #r2为累加器
    li r2 0x0

    ; #a1 - 0x201
    li r0 0x2
    sll r0 0x0
    addiu r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 0x201
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a1 - 0x1ff
    addiu r0 0xfe
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 0x1ff
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
    ; #a1 - 1
    li r0 0x1
    subu r3 r0 r1
    lw r1 r5 0x0
    addu r2 r5 r2
    ; #a1 + 1
    li r0 0x1
    addu r3 r0 r1
    lw r1 r5 0x0
    subu r2 r5 r2
; #let r2 > 0: 检查最高位
    li r0 0x80
    sll r0 0x0
    and r0 r2
    cmpi r0 0x0
    bteqz cont_zone2_a0
    nop
; #取相反数：按位取反加一
reverse_zone3_a1:
    li r0 0x0
    addiu r0 0xff
    subu r0 r2 r2
    addiu r2 0x1
; #得到的r2至多为7位(128)，而存到VGA中最多为(16)，
; #除以4 v / 除以2，高出部分做clipping
; #r2 => r1.r/g/b
cont_zone3_a1:
    addiu r2 0x8
    sra r2 0x4
    li r1 0x0
    sll r2 0x5
    addu r1 r2 r1
    srl r2 0x3
    addu r1 r2 r1
    srl 0x3
    addu r1 r2 r1
; #write back: 
    ; #恢复[r4 r3]
    addiu r3 0xff
    sra r3 0x1
    li r4 0x5
    ; #读出之前偶数像素rgb到r2
    ; #r2 + r1 写入内存: addr
    excpg r4
    lw r3 r2 0x0
    sll r2 0x0
    addu r1 r2 r1
    sw r3 r1 0x0

;; #jump
    ; #r5: mask 0x00ff
    li r5 0xff
    addiu r3 0x2
    ; #r5 = r5 and r3
    and r5 r3
    cmpi r5 0x0
    bteqz add1_zone3
    nop
; #不换行
minus1_zone3:
    addiu r3 0xff
    b sobel_zone3_loop
; #换行：从一行的最后调到下一行首个像素
add1_zone3:
    addiu r3 0x1
; #判断：[r4 r3] [4 ff01]
    li r5 0x7f
    sll r5 0x0
    addiu r5 0x1
    cmp r3 r5
    btnez sobel_zone3_loop
    nop
    b waiting #; b sobel_zone4



waiting:
; #MEM[CAM_SGN] = 1
cam_request:
    li r0 0x1
    li r1 0xbf04
    sw r1 r0 0x0

; #while MEM[CAM_SGN]==0, loop
loop_:
    lw r1 r0 0x0
    cmpi r0 0x0
    btnez loop

; #goto arith
leave_:
    b arith
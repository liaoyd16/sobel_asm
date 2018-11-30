; # to be tested on simulator
; #3x3
; #R3_STORE := 0xfffe
; #R4_STORE := 0xffff

grey:
    li r3 0xc0
    sll r3 0x0
    li r4 0x1
; #计算(w, h)的灰度和:
grey_calc:
    ; #rgb = MEM[addr]
    lw r3 r2 0x0

    ; #腾出r3, r4
    ; #MEM[R4_STORE] = r4
    li r0 0x0
    addiu r0 0xfe
    sw r0 r3 0x0
    ; #MEM[R3_STORE] = r3
    li r0 0x0
    addiu r0 0xff
    sw r0 r4 0x0

    ; #blue: 0...011111, r3 = 0...011111 => r2
    ; #green: 0000011111100000, r3 = 00000111110....0 => r1
    ; #red: 111110...0, r3 = 111110...0 => r0
    ; #r2:rgb = r5+g5+b5

    addiu3 r2 r1 0x0
    addiu3 r2 r0 0x0
    ; #blue
    li r3 0x1f
    and r2 r3
    ; #green
    sll r3 0x6
    and r1 r3
    ; #red
    sll r3 0x5
    and r0 r3

    srl r0 0x0
    srl r0 0x3
    srl r1 0x6

    ; #ry rz 写反了！
    addu r2 r0 r2
    addu r2 r1 r2

    ; #r4 = MEM[R4_STORE]
    ; #r3 = MEM[R3_STORE]
    li r0 0x0
    addiu r0 0xfe
    lw r0 r3 0x0
    li r0 0x0
    addiu r0 0xff
    lw r0 r4 0x0

    ; #MEM[r3]=r2
    sw r3 r2 0x0

    ; #r3 r4 更新
    addiu r3 0x1
    cmpi r3 0x9
    btnez grey_calc ;# cont => grey_calc
    nop
addr4:
    ; #r4 == 4?
    addiu r4 0x1
    cmpi r4 0x2
    jr r7
    nop
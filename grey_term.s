    li r3 c0
    sll r3 0
    li r4 1
grey_calc:
    lw r3 r2 0
    li r0 0
    addiu r0 fe
    sw r0 r3 0
    li r0 0
    addiu r0 ff
    sw r0 r4 0
    addiu3 r2 r1 0
    addiu3 r2 r0 0
    li r3 1f
    and r2 r3
    sll r3 6
    and r1 r3
    sll r3 5
    and r0 r3
    srl r0 0
    srl r0 3
    srl r1 6
    addu r2 r0 r2
    addu r2 r1 r2
    li r0 0
    addiu r0 fe
    lw r0 r3 0
    li r0 0
    addiu r0 ff
    lw r0 r4 0
    sw r3 r2 0
    addiu r3 1
    cmpi r3 9
    btnez e2
    nop
    addiu r4 1
    cmpi r4 2
    jr r7
    nop
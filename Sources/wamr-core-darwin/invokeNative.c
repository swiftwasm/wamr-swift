/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */
__asm__(
"    .text\n"
"    .align 2\n"
#ifndef BH_PLATFORM_DARWIN
".globl invokeNative\n"
"    .type    invokeNative, @function\n"
"invokeNative:\n"
#else
".globl _invokeNative\n"
"_invokeNative:\n"
#endif /* end of BH_PLATFORM_DARWIN */
    /*  rdi - function ptr */
    /*  rsi - argv */
    /*  rdx - n_stacks */
"\n"
"    push %rbp\n"
"    mov %rsp, %rbp\n"
"\n"
"    mov %rdx, %r10\n"
"    mov %rsp, %r11      \n"/* Check that stack is aligned on */
"    and $8, %r11        \n"/* 16 bytes. This code may be removed */
"    je check_stack_succ \n"/* when we are sure that compiler always */
"    int3                \n"/* calls us with aligned stack */
"check_stack_succ:\n"
"    mov %r10, %r11      \n"/* Align stack on 16 bytes before pushing */
"    and $1, %r11        \n"/* stack arguments in case we have an odd */
"    shl $3, %r11        \n"/* number of stack arguments */
"    sub %r11, %rsp\n"
    /* store memory args */
"    movq %rdi, %r11     \n"/* func ptr */
"    movq %r10, %rcx     \n"/* counter */
"    lea 64+48-8(%rsi,%rcx,8), %r10\n"
"    sub %rsp, %r10\n"
"    cmpq $0, %rcx\n"
"    je push_args_end\n"
"push_args:\n"
"    push 0(%rsp,%r10)\n"
"    loop push_args\n"
"push_args_end:\n"
    /* fill all fp args */
"    movq 0x00(%rsi), %xmm0\n"
"    movq 0x08(%rsi), %xmm1\n"
"    movq 0x10(%rsi), %xmm2\n"
"    movq 0x18(%rsi), %xmm3\n"
"    movq 0x20(%rsi), %xmm4\n"
"    movq 0x28(%rsi), %xmm5\n"
"    movq 0x30(%rsi), %xmm6\n"
"    movq 0x38(%rsi), %xmm7\n"
"\n"
    /* fill all int args */
"    movq 0x40(%rsi), %rdi\n"
"    movq 0x50(%rsi), %rdx\n"
"    movq 0x58(%rsi), %rcx\n"
"    movq 0x60(%rsi), %r8\n"
"    movq 0x68(%rsi), %r9\n"
"    movq 0x48(%rsi), %rsi\n"
"\n"
"    call *%r11\n"
"    leave\n"
"    ret\n"
);

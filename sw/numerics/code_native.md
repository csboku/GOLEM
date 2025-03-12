# INTEL
julia> @code_native m1*m2
	.text
	.file	"*"
	.globl	"julia_*_187"                   # -- Begin function julia_*_187
	.p2align	4, 0x90
	.type	"julia_*_187",@function
"julia_*_187":                          # @"julia_*_187"
; ┌ @ /cache/build/builder-amdci4-4/julialang/julia-release-1-dot-10/usr/share/julia/stdlib/v1.10/LinearAlgebra/src/matmul.jl:111 within `*`
# %bb.0:                                # %L72
	push	rbp
	mov	rbp, rsp
	push	r15
	push	r14
	push	rbx
	sub	rsp, 24
	mov	r14, rsi
	mov	r15, rdi
	vxorps	xmm0, xmm0, xmm0
	vmovaps	xmmword ptr [rbp - 48], xmm0
	mov	qword ptr [rbp - 32], 0
	#APP
	mov	rax, qword ptr fs:[0]
	#NO_APP
	mov	rbx, qword ptr [rax - 8]
; │ @ /cache/build/builder-amdci4-4/julialang/julia-release-1-dot-10/usr/share/julia/stdlib/v1.10/LinearAlgebra/src/matmul.jl:113 within `*`
; │┌ @ array.jl:190 within `size`
	mov	qword ptr [rbp - 48], 4
	mov	rax, qword ptr [rbx]
	mov	qword ptr [rbp - 40], rax
	lea	rax, [rbp - 48]
	mov	qword ptr [rbx], rax
	mov	rsi, qword ptr [rdi + 24]
	mov	rdx, qword ptr [r14 + 32]
	movabs	rdi, 23045600608016
	movabs	rax, 23045711542432
; │└
; │┌ @ array.jl:420 within `similar`
; ││┌ @ boot.jl:487 within `Array` @ boot.jl:479
	call	rax
	mov	qword ptr [rbp - 32], rax
; │└└
; │┌ @ /cache/build/builder-amdci4-4/julialang/julia-release-1-dot-10/usr/share/julia/stdlib/v1.10/LinearAlgebra/src/matmul.jl:237 within `mul!` @ /cache/build/builder-amdci4-4/julialang/julia-release-1-dot-10/usr/share/julia/stdlib/v1.10/LinearAlgebra/src/matmul.jl:263
; ││┌ @ /cache/build/builder-amdci4-4/julialang/julia-release-1-dot-10/usr/share/julia/stdlib/v1.10/LinearAlgebra/src/matmul.jl:352 within `generic_matmatmul!`
	movabs	r9, offset .L_j_const2
	movabs	r10, offset "j_gemm_wrapper!_189"
	mov	rdi, rax
	mov	esi, 1308622848
	mov	edx, 1308622848
	mov	rcx, r15
	mov	r8, r14
	call	r10
	mov	rcx, qword ptr [rbp - 40]
	mov	qword ptr [rbx], rcx
; ││└
; ││ @ /cache/build/builder-amdci4-4/julialang/julia-release-1-dot-10/usr/share/julia/stdlib/v1.10/LinearAlgebra/src/matmul.jl:237 within `mul!`
	add	rsp, 24
	pop	rbx
	pop	r14
	pop	r15
	pop	rbp
	ret
.Lfunc_end0:
	.size	"julia_*_187", .Lfunc_end0-"julia_*_187"
; └└
                                        # -- End function
	.type	.L_j_const1,@object             # @_j_const1
	.section	.rodata.cst8,"aM",@progbits,8
	.p2align	2
.L_j_const1:
	.long	1308622848                      # 0x4e000000
	.long	1308622848                      # 0x4e000000
	.size	.L_j_const1, 8

	.type	.L_j_const2,@object             # @_j_const2
	.section	.rodata.str1.1,"aMS",@progbits,1
.L_j_const2:
	.asciz	"\001"
	.size	.L_j_const2, 2

	.type	.L_j_const3,@object             # @_j_const3
	.section	.rodata,"a",@progbits
	.p2align	2
.L_j_const3:
	.long	1308622848                      # 0x4e000000
	.long	1409286144                      # 0x54000000
	.long	1124073472                      # 0x43000000
	.size	.L_j_const3, 12

	.section	".note.GNU-stack","",@progbits

# AMD
julia> @code_native m1*m2
	.text
	.file	"*"
	.globl	"julia_*_1124"                  # -- Begin function julia_*_1124
	.p2align	4, 0x90
	.type	"julia_*_1124",@function
"julia_*_1124":                         # @"julia_*_1124"
; Function Signature: *(Array{Float64, 2}, Array{Float64, 2})
; ┌ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:122 within `*`
# %bb.0:                                # %top
; │ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl within `*`
	#DEBUG_VALUE: *:A <- [DW_OP_deref] $rdi
	#DEBUG_VALUE: *:B <- [DW_OP_deref] $rsi
	push	rbp
	mov	rbp, rsp
	push	r15
	push	r14
	push	r13
	push	r12
	push	rbx
	sub	rsp, 56
	vxorps	xmm0, xmm0, xmm0
	#APP
	mov	rax, qword ptr fs:[0]
	#NO_APP
	mov	rdx, rsi
	movabs	rcx, 9223372036854775806
	vmovaps	xmmword ptr [rbp - 64], xmm0
	mov	qword ptr [rbp - 48], 0
	mov	r12, qword ptr [rax - 8]
	mov	qword ptr [rbp - 64], 4
	mov	rax, qword ptr [r12]
	mov	qword ptr [rbp - 56], rax
	lea	rax, [rbp - 64]
	mov	qword ptr [r12], rax
	#DEBUG_VALUE: *:B <- [DW_OP_deref] 0
	#DEBUG_VALUE: *:A <- [DW_OP_deref] 0
; │ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:124 within `*`
; │┌ @ array.jl:191 within `size`
	mov	rbx, qword ptr [rdi + 16]
	mov	r14, qword ptr [rsi + 24]
; │└
; │┌ @ array.jl:372 within `similar`
; ││┌ @ boot.jl:592 within `Array` @ boot.jl:582
; │││┌ @ boot.jl:571 within `checked_dims`
; ││││┌ @ boot.jl:541 within `_checked_mul_dims`
	mov	rsi, rbx
	imul	rsi, r14
	seto	al
; │││││ @ boot.jl:545 within `_checked_mul_dims`
	cmp	r14, rcx
; ││││└
; ││││ @ boot.jl:572 within `checked_dims`
	ja	.LBB0_8
# %bb.1:                                # %top
	cmp	rbx, rcx
	ja	.LBB0_8
# %bb.2:                                # %top
	test	al, al
	jne	.LBB0_8
# %bb.3:                                # %L17
	mov	qword ptr [rbp - 88], rdx       # 8-byte Spill
	mov	qword ptr [rbp - 80], rdi       # 8-byte Spill
; │││└
; │││┌ @ boot.jl:535 within `new_as_memoryref`
; ││││┌ @ boot.jl:512 within `GenericMemory`
	test	rsi, rsi
	je	.LBB0_4
# %bb.6:                                # %L21
; │││││ @ boot.jl:516 within `GenericMemory`
	movabs	rdi, offset ".L+Core.GenericMemory#1135.jit"
	movabs	rax, offset jl_alloc_genericmemory
	call	rax
	mov	r15, rax
	jmp	.LBB0_7
.LBB0_4:                                # %L19
	movabs	rax, offset ".L+Core.GenericMemory#1135.jit"
; │││││ @ boot.jl:514 within `GenericMemory`
	mov	r15, qword ptr [rax + 32]
	test	r15, r15
	je	.LBB0_5
.LBB0_7:                                # %L23
; ││││└
; ││││┌ @ boot.jl:522 within `memoryref`
	mov	r13, qword ptr [r15 + 8]
	mov	qword ptr [rbp - 48], r15
	mov	qword ptr [rbp - 72], r12       # 8-byte Spill
; │││└└
	movabs	rax, offset ijl_gc_pool_alloc_instrumented
	mov	esi, 848
	mov	edx, 48
	mov	rdi, qword ptr [r12 + 16]
	movabs	r12, 140321442181488
	add	r12, 134232416
	mov	rcx, r12
	call	rax
	mov	rcx, qword ptr [rbp - 80]       # 8-byte Reload
	mov	r8, qword ptr [rbp - 88]        # 8-byte Reload
; │└└
; │┌ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:253 within `mul!` @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:285
; ││┌ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:287 within `_mul!`
; │││┌ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:381 within `generic_matmatmul!`
	movabs	r9, offset ".L_j_const#1"
	movabs	r10, offset "j_gemm_wrapper!_1140"
	mov	rdi, rax
	mov	esi, 1308622848
	mov	edx, 1308622848
; │└└└
; │┌ @ array.jl:372 within `similar`
; ││┌ @ boot.jl:592 within `Array` @ boot.jl:582
	mov	qword ptr [rax - 8], r12
	mov	qword ptr [rax], r13
	mov	qword ptr [rax + 8], r15
	mov	qword ptr [rax + 16], rbx
	mov	qword ptr [rax + 24], r14
	mov	qword ptr [rbp - 48], rax
; │└└
; │┌ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:253 within `mul!` @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:285
; ││┌ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:287 within `_mul!`
; │││┌ @ /cache/build/builder-demeter6-3/julialang/julia-release-1-dot-11/usr/share/julia/stdlib/v1.11/LinearAlgebra/src/matmul.jl:381 within `generic_matmatmul!`
	call	r10
	mov	rcx, qword ptr [rbp - 56]
	mov	rdx, qword ptr [rbp - 72]       # 8-byte Reload
	mov	qword ptr [rdx], rcx
	add	rsp, 56
	pop	rbx
	pop	r12
	pop	r13
	pop	r14
	pop	r15
	pop	rbp
	ret
.LBB0_8:                                # %L13
; │└└└
; │┌ @ array.jl:372 within `similar`
; ││┌ @ boot.jl:592 within `Array` @ boot.jl:582
; │││┌ @ boot.jl:572 within `checked_dims`
	movabs	rdi, offset ".Ljl_global#1130.jit"
	movabs	rax, offset j_ArgumentError_1129
	call	rax
	mov	qword ptr [rbp - 48], rax
	movabs	r14, 140321442181488
	mov	rbx, rax
	movabs	rax, offset ijl_gc_pool_alloc_instrumented
	mov	esi, 752
	mov	edx, 16
	mov	rdi, qword ptr [r12 + 16]
	mov	rcx, r14
	call	rax
	movabs	rcx, offset ijl_throw
	mov	rdi, rax
	mov	qword ptr [rax - 8], r14
	mov	qword ptr [rax], rbx
	call	rcx
.LBB0_5:                                # %fail
; │││└
; │││┌ @ boot.jl:535 within `new_as_memoryref`
; ││││┌ @ boot.jl:514 within `GenericMemory`
	movabs	rax, offset jl_undefref_exception
	mov	rdi, qword ptr [rax]
	movabs	rax, offset ijl_throw
	call	rax
.Lfunc_end0:
	.size	"julia_*_1124", .Lfunc_end0-"julia_*_1124"
; └└└└└
                                        # -- End function
	.type	".L_j_const#1",@object          # @"_j_const#1"
	.section	.rodata.str1.1,"aMS",@progbits,1
".L_j_const#1":
	.asciz	"\001"
	.size	".L_j_const#1", 2

.set ".L+Core.GenericMemory#1135.jit", 140321389060016
	.size	".L+Core.GenericMemory#1135.jit", 8
.set ".L+Core.ArgumentError#1132.jit", 140321442181488
	.size	".L+Core.ArgumentError#1132.jit", 8
.set ".Ljl_global#1130.jit", 140321478850224
	.size	".Ljl_global#1130.jit", 8
.set ".L+Core.Array#1138.jit", 140321576413904
	.size	".L+Core.Array#1138.jit", 8
	.section	".note.GNU-stack","",@progbits

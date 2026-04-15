; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"
target datalayout = "e-p3:32:32-p4:32:32-p5:32:32-p6:32:32-p7:32:32-i64:64-i128:128-i256:256-v16:16-v32:32-n16:32:64"

@global_smem = external addrspace(3) global [0 x i8], align 16

; Function Attrs: nounwind
define ptx_kernel void @_helion_swiglu_kernel_fn_dot(ptr addrspace(1) %0, ptr addrspace(1) %1, ptr addrspace(1) %2, ptr addrspace(1) %3, ptr addrspace(1) %4, ptr addrspace(1) readnone captures(none) %5) local_unnamed_addr #0 !dbg !4 {
  %7 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x(), !dbg !7
  %8 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.y(), !dbg !7
  %9 = tail call i32 @llvm.nvvm.read.ptx.sreg.ctaid.z(), !dbg !7
  %10 = tail call i32 @llvm.nvvm.read.ptx.sreg.nctaid.x(), !dbg !7
  %11 = tail call i32 @llvm.nvvm.read.ptx.sreg.nctaid.y(), !dbg !7
  %12 = mul nuw i32 %9, %11, !dbg !7
  %13 = add nuw i32 %12, %8, !dbg !7
  %14 = mul i32 %13, %10, !dbg !7
  %15 = add i32 %14, %7, !dbg !7
  %16 = mul i32 %15, 384, !dbg !7
  %17 = sext i32 %16 to i64, !dbg !7
  %18 = getelementptr i8, ptr addrspace(1) %4, i64 %17, !dbg !7
  %19 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !7
  %20 = and i32 %19, 127, !dbg !7
  %21 = icmp samesign ult i32 %20, 32, !dbg !7
  %22 = getelementptr i32, ptr addrspace(3) @global_smem, i32 %20, !dbg !7
  tail call void asm sideeffect "@$2 st.shared.b32 [ $0 + 0 ], $1;", "r,r,b"(ptr addrspace(3) %22, <1 x i32> zeroinitializer, i1 %21) #6, !dbg !7
  tail call void @llvm.nvvm.bar.warp.sync(i32 -1), !dbg !7
  %23 = icmp eq i32 %20, 0, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_address.shared::cta.b1024.b64 [ $0 + 0 ], $1;", "l,l,b"(ptr addrspace(3) @global_smem, ptr addrspace(1) %0, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$1 tensormap.replace.tile.rank.shared::cta.b1024.b32 [ $0 + 0 ], 0x1;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.replace.tile.box_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 32, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.replace.tile.box_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 128, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 8192, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 8192, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_stride.shared::cta.b1024.b64 [ $0 + 0 ], 0x0, $1;", "l,l,b"(ptr addrspace(3) @global_smem, i64 16384, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.replace.tile.element_stride.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 1, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.replace.tile.element_stride.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 1, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$1 tensormap.replace.tile.elemtype.shared::cta.b1024.b32 [ $0 + 0 ], 0xa;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$1 tensormap.replace.tile.interleave_layout.shared::cta.b1024.b32 [ $0 + 0 ], 0x0;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$1 tensormap.replace.tile.swizzle_mode.shared::cta.b1024.b32 [ $0 + 0 ], 0x2;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$1 tensormap.replace.tile.fill_mode.shared::cta.b1024.b32 [ $0 + 0 ], 0x0;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !7
  tail call void asm sideeffect "@$2 tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [ $0 + 0 ], [ $1 + 0 ], 0x80;", "l,l,b"(ptr addrspace(1) %18, ptr addrspace(3) @global_smem, i1 %21) #6, !dbg !7
  tail call void asm sideeffect "@$1 fence.proxy.tensormap::generic.acquire.gpu [ $0 + 0 ], 0x80;\0A\09@$2 cp.async.bulk.commit_group ;\0A\09@$3 cp.async.bulk.wait_group.read 0 ;", "l,b,b,b"(ptr addrspace(1) %18, i1 %21, i1 %21, i1 %21) #6, !dbg !7
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !7
  %24 = addrspacecast ptr addrspace(1) %18 to ptr, !dbg !7
  %25 = add i32 %16, 128, !dbg !8
  %26 = sext i32 %25 to i64, !dbg !8
  %27 = getelementptr i8, ptr addrspace(1) %4, i64 %26, !dbg !8
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !8
  tail call void asm sideeffect "@$2 st.shared.b32 [ $0 + 0 ], $1;", "r,r,b"(ptr addrspace(3) %22, <1 x i32> zeroinitializer, i1 %21) #6, !dbg !8
  tail call void @llvm.nvvm.bar.warp.sync(i32 -1), !dbg !8
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_address.shared::cta.b1024.b64 [ $0 + 0 ], $1;", "l,l,b"(ptr addrspace(3) @global_smem, ptr addrspace(1) %2, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$1 tensormap.replace.tile.rank.shared::cta.b1024.b32 [ $0 + 0 ], 0x1;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$2 tensormap.replace.tile.box_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 32, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$2 tensormap.replace.tile.box_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 32, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 8192, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 8192, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_stride.shared::cta.b1024.b64 [ $0 + 0 ], 0x0, $1;", "l,l,b"(ptr addrspace(3) @global_smem, i64 16384, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$2 tensormap.replace.tile.element_stride.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 1, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$2 tensormap.replace.tile.element_stride.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 1, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$1 tensormap.replace.tile.elemtype.shared::cta.b1024.b32 [ $0 + 0 ], 0xa;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$1 tensormap.replace.tile.interleave_layout.shared::cta.b1024.b32 [ $0 + 0 ], 0x0;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$1 tensormap.replace.tile.swizzle_mode.shared::cta.b1024.b32 [ $0 + 0 ], 0x2;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$1 tensormap.replace.tile.fill_mode.shared::cta.b1024.b32 [ $0 + 0 ], 0x0;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !8
  tail call void asm sideeffect "@$2 tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [ $0 + 0 ], [ $1 + 0 ], 0x80;", "l,l,b"(ptr addrspace(1) %27, ptr addrspace(3) @global_smem, i1 %21) #6, !dbg !8
  tail call void asm sideeffect "@$1 fence.proxy.tensormap::generic.acquire.gpu [ $0 + 0 ], 0x80;\0A\09@$2 cp.async.bulk.commit_group ;\0A\09@$3 cp.async.bulk.wait_group.read 0 ;", "l,b,b,b"(ptr addrspace(1) %27, i1 %21, i1 %21, i1 %21) #6, !dbg !8
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !8
  %28 = addrspacecast ptr addrspace(1) %27 to ptr, !dbg !8
  %29 = add i32 %16, 256, !dbg !9
  %30 = sext i32 %29 to i64, !dbg !9
  %31 = getelementptr i8, ptr addrspace(1) %4, i64 %30, !dbg !9
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !9
  tail call void asm sideeffect "@$2 st.shared.b32 [ $0 + 0 ], $1;", "r,r,b"(ptr addrspace(3) %22, <1 x i32> zeroinitializer, i1 %21) #6, !dbg !9
  tail call void @llvm.nvvm.bar.warp.sync(i32 -1), !dbg !9
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_address.shared::cta.b1024.b64 [ $0 + 0 ], $1;", "l,l,b"(ptr addrspace(3) @global_smem, ptr addrspace(1) %3, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$1 tensormap.replace.tile.rank.shared::cta.b1024.b32 [ $0 + 0 ], 0x1;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$2 tensormap.replace.tile.box_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 32, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$2 tensormap.replace.tile.box_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 128, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 8192, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_dim.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 8192, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$2 tensormap.replace.tile.global_stride.shared::cta.b1024.b64 [ $0 + 0 ], 0x0, $1;", "l,l,b"(ptr addrspace(3) @global_smem, i64 16384, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$2 tensormap.replace.tile.element_stride.shared::cta.b1024.b32 [ $0 + 0 ], 0x0, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 1, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$2 tensormap.replace.tile.element_stride.shared::cta.b1024.b32 [ $0 + 0 ], 0x1, $1;", "l,r,b"(ptr addrspace(3) @global_smem, i32 1, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$1 tensormap.replace.tile.elemtype.shared::cta.b1024.b32 [ $0 + 0 ], 0xa;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$1 tensormap.replace.tile.interleave_layout.shared::cta.b1024.b32 [ $0 + 0 ], 0x0;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$1 tensormap.replace.tile.swizzle_mode.shared::cta.b1024.b32 [ $0 + 0 ], 0x2;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$1 tensormap.replace.tile.fill_mode.shared::cta.b1024.b32 [ $0 + 0 ], 0x0;", "l,b"(ptr addrspace(3) @global_smem, i1 %23) #6, !dbg !9
  tail call void asm sideeffect "@$2 tensormap.cp_fenceproxy.global.shared::cta.tensormap::generic.release.gpu.sync.aligned [ $0 + 0 ], [ $1 + 0 ], 0x80;", "l,l,b"(ptr addrspace(1) %31, ptr addrspace(3) @global_smem, i1 %21) #6, !dbg !9
  tail call void asm sideeffect "@$1 fence.proxy.tensormap::generic.acquire.gpu [ $0 + 0 ], 0x80;\0A\09@$2 cp.async.bulk.commit_group ;\0A\09@$3 cp.async.bulk.wait_group.read 0 ;", "l,b,b,b"(ptr addrspace(1) %31, i1 %21, i1 %21, i1 %21) #6, !dbg !9
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !9
  %32 = lshr i32 %7, 8, !dbg !10
  %33 = and i32 %32, 8388600, !dbg !10
  %34 = sub nsw i32 64, %33, !dbg !11
  %35 = tail call i32 @llvm.smin.i32(i32 %34, i32 8), !dbg !12
  %36 = and i32 %7, 2047, !dbg !13
  %37 = sdiv i32 %36, %35, !dbg !14
  %38 = mul i32 %37, %35, !dbg !15
  %.decomposed = sub i32 %36, %38, !dbg !15
  %39 = add nuw nsw i32 %.decomposed, %33, !dbg !16
  %40 = shl nuw nsw i32 %39, 7, !dbg !17
  %41 = shl nsw i32 %37, 5, !dbg !18
  %42 = and i32 %19, 96, !dbg !19
  %43 = lshr exact i32 %42, 5, !dbg !19
  %44 = or disjoint i32 %43, 4, !dbg !19
  %45 = or disjoint i32 %43, 8, !dbg !19
  %46 = or disjoint i32 %43, 12, !dbg !19
  %47 = or disjoint i32 %43, 16, !dbg !19
  %48 = or disjoint i32 %43, 20, !dbg !19
  %49 = or disjoint i32 %43, 24, !dbg !19
  %50 = or disjoint i32 %43, 28, !dbg !19
  %51 = and i32 %19, 31, !dbg !19
  %52 = or disjoint i32 %41, %43, !dbg !20
  %53 = or disjoint i32 %41, %44, !dbg !20
  %54 = or disjoint i32 %41, %45, !dbg !20
  %55 = or disjoint i32 %41, %46, !dbg !20
  %56 = or disjoint i32 %41, %47, !dbg !20
  %57 = or disjoint i32 %41, %48, !dbg !20
  %58 = or disjoint i32 %41, %49, !dbg !20
  %59 = or disjoint i32 %41, %50, !dbg !20
  %60 = shl nsw i32 %52, 13, !dbg !21
  %61 = shl nsw i32 %53, 13, !dbg !21
  %62 = shl nsw i32 %54, 13, !dbg !21
  %63 = shl nsw i32 %55, 13, !dbg !21
  %64 = shl nsw i32 %56, 13, !dbg !21
  %65 = shl nsw i32 %57, 13, !dbg !21
  %66 = shl nsw i32 %58, 13, !dbg !21
  %67 = shl nsw i32 %59, 13, !dbg !21
  tail call void asm sideeffect "@$0 mbarrier.init.shared::cta.b64 [$1], 1;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43008)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.init.shared::cta.b64 [$1], 1;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43016)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.init.shared::cta.b64 [$1], 1;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43024)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.init.shared::cta.b64 [$1], 1;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43032)) #6, !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.init.shared::cta.b64 [$1], 1;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43040)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.init.shared::cta.b64 [$1], 1;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43048)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.init.shared::cta.b64 [$1], 1;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43056)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.init.shared::cta.b64 [$1], 1;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43064)) #6, !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.arrive.expect_tx.shared.b64 _, [$1], 8192;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43008)) #6, !dbg !22
  tail call void asm sideeffect "fence.proxy.async.shared::cta;", ""() #6, !dbg !23
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !23
  %68 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !23
  %69 = extractvalue { i32, i1 } %68, 1, !dbg !23
  %70 = and i1 %21, %69, !dbg !23
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [$1], [$2, {$3, $4}], [$5];", "b,r,l,r,r,r"(i1 %70, ptr addrspace(3) @global_smem, ptr %24, i32 0, i32 %40, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43008)) #6, !dbg !23
  tail call void asm sideeffect "@$0 mbarrier.arrive.expect_tx.shared.b64 _, [$1], 2048;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43040)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !24
  %71 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !24
  %72 = extractvalue { i32, i1 } %71, 1, !dbg !24
  %73 = and i1 %21, %72, !dbg !24
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [$1], [$2, {$3, $4}], [$5];", "b,r,l,r,r,r"(i1 %73, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 32768), ptr %28, i32 0, i32 %41, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43040)) #6, !dbg !24
  tail call void asm sideeffect "@$0 mbarrier.arrive.expect_tx.shared.b64 _, [$1], 8192;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43016)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !23
  %74 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !23
  %75 = extractvalue { i32, i1 } %74, 1, !dbg !23
  %76 = and i1 %21, %75, !dbg !23
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [$1], [$2, {$3, $4}], [$5];", "b,r,l,r,r,r"(i1 %76, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 8192), ptr %24, i32 32, i32 %40, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43016)) #6, !dbg !23
  tail call void asm sideeffect "@$0 mbarrier.arrive.expect_tx.shared.b64 _, [$1], 2048;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43048)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !24
  %77 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !24
  %78 = extractvalue { i32, i1 } %77, 1, !dbg !24
  %79 = and i1 %21, %78, !dbg !24
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [$1], [$2, {$3, $4}], [$5];", "b,r,l,r,r,r"(i1 %79, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 34816), ptr %28, i32 32, i32 %41, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43048)) #6, !dbg !24
  tail call void asm sideeffect "@$0 mbarrier.arrive.expect_tx.shared.b64 _, [$1], 8192;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43024)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !23
  %80 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !23
  %81 = extractvalue { i32, i1 } %80, 1, !dbg !23
  %82 = and i1 %21, %81, !dbg !23
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [$1], [$2, {$3, $4}], [$5];", "b,r,l,r,r,r"(i1 %82, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 16384), ptr %24, i32 64, i32 %40, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43024)) #6, !dbg !23
  tail call void asm sideeffect "@$0 mbarrier.arrive.expect_tx.shared.b64 _, [$1], 2048;", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43056)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !24
  %83 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !24
  %84 = extractvalue { i32, i1 } %83, 1, !dbg !24
  %85 = and i1 %21, %84, !dbg !24
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [$1], [$2, {$3, $4}], [$5];", "b,r,l,r,r,r"(i1 %85, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 36864), ptr %28, i32 64, i32 %41, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43056)) #6, !dbg !24
  %86 = shl nuw nsw i32 %19, 1
  %87 = and i32 %86, 126
  %88 = and i32 %19, 64
  %89 = icmp eq i32 %88, 0
  %90 = select i1 %89, i32 0, i32 144
  %91 = xor i32 %90, %87
  %92 = getelementptr inbounds nuw i8, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 40960), i32 %91
  %93 = getelementptr inbounds nuw i8, ptr addrspace(3) %92, i32 512
  %94 = getelementptr inbounds nuw i8, ptr addrspace(3) %92, i32 1024
  %95 = getelementptr inbounds nuw i8, ptr addrspace(3) %92, i32 1536
  %96 = xor i32 %91, 288
  %97 = getelementptr inbounds nuw i8, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 40960), i32 %96
  %98 = getelementptr inbounds nuw i8, ptr addrspace(3) %97, i32 512
  %99 = getelementptr inbounds nuw i8, ptr addrspace(3) %97, i32 1024
  %100 = getelementptr inbounds nuw i8, ptr addrspace(3) %97, i32 1536
  %101 = lshr exact i32 ptrtoint (ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 40960) to i32), 4
  %102 = and i32 %101, 16383
  %103 = zext nneg i32 %102 to i64
  %104 = or disjoint i64 %103, -9223371899415822336
  %105 = add nuw nsw i64 %103, -9223371899415822334
  %106 = zext nneg i32 %51 to i64, !dbg !22
  %107 = sext i32 %60 to i64, !dbg !22
  %108 = sext i32 %61 to i64, !dbg !22
  %109 = sext i32 %62 to i64, !dbg !22
  %110 = sext i32 %63 to i64, !dbg !22
  %111 = sext i32 %64 to i64, !dbg !22
  %112 = sext i32 %65 to i64, !dbg !22
  %113 = sext i32 %66 to i64, !dbg !22
  %114 = sext i32 %67 to i64, !dbg !22
  %invariant.gep = getelementptr bfloat, ptr addrspace(1) %1, i64 %107, !dbg !22
  %invariant.gep131 = getelementptr bfloat, ptr addrspace(1) %1, i64 %108, !dbg !22
  %invariant.gep133 = getelementptr bfloat, ptr addrspace(1) %1, i64 %109, !dbg !22
  %invariant.gep135 = getelementptr bfloat, ptr addrspace(1) %1, i64 %110, !dbg !22
  %invariant.gep137 = getelementptr bfloat, ptr addrspace(1) %1, i64 %111, !dbg !22
  %invariant.gep139 = getelementptr bfloat, ptr addrspace(1) %1, i64 %112, !dbg !22
  %invariant.gep141 = getelementptr bfloat, ptr addrspace(1) %1, i64 %113, !dbg !22
  %invariant.gep143 = getelementptr bfloat, ptr addrspace(1) %1, i64 %114, !dbg !22
  br label %115, !dbg !22

115:                                              ; preds = %6, %115
  %indvars.iv = phi i64 [ 0, %6 ], [ %indvars.iv.next, %115 ]
  %116 = phi i32 [ 0, %6 ], [ %188, %115 ]
  %117 = phi i32 [ -1, %6 ], [ %186, %115 ]
  %118 = phi i32 [ 2, %6 ], [ %395, %115 ]
  %119 = phi float [ 0.000000e+00, %6 ], [ %343, %115 ]
  %120 = phi float [ 0.000000e+00, %6 ], [ %344, %115 ]
  %121 = phi float [ 0.000000e+00, %6 ], [ %345, %115 ]
  %122 = phi float [ 0.000000e+00, %6 ], [ %346, %115 ]
  %123 = phi float [ 0.000000e+00, %6 ], [ %347, %115 ]
  %124 = phi float [ 0.000000e+00, %6 ], [ %348, %115 ]
  %125 = phi float [ 0.000000e+00, %6 ], [ %349, %115 ]
  %126 = phi float [ 0.000000e+00, %6 ], [ %350, %115 ]
  %127 = phi float [ 0.000000e+00, %6 ], [ %351, %115 ]
  %128 = phi float [ 0.000000e+00, %6 ], [ %352, %115 ]
  %129 = phi float [ 0.000000e+00, %6 ], [ %353, %115 ]
  %130 = phi float [ 0.000000e+00, %6 ], [ %354, %115 ]
  %131 = phi float [ 0.000000e+00, %6 ], [ %355, %115 ]
  %132 = phi float [ 0.000000e+00, %6 ], [ %356, %115 ]
  %133 = phi float [ 0.000000e+00, %6 ], [ %357, %115 ]
  %134 = phi float [ 0.000000e+00, %6 ], [ %358, %115 ]
  %135 = phi float [ 0.000000e+00, %6 ], [ %377, %115 ]
  %136 = phi float [ 0.000000e+00, %6 ], [ %378, %115 ]
  %137 = phi float [ 0.000000e+00, %6 ], [ %379, %115 ]
  %138 = phi float [ 0.000000e+00, %6 ], [ %380, %115 ]
  %139 = phi float [ 0.000000e+00, %6 ], [ %381, %115 ]
  %140 = phi float [ 0.000000e+00, %6 ], [ %382, %115 ]
  %141 = phi float [ 0.000000e+00, %6 ], [ %383, %115 ]
  %142 = phi float [ 0.000000e+00, %6 ], [ %384, %115 ]
  %143 = phi float [ 0.000000e+00, %6 ], [ %385, %115 ]
  %144 = phi float [ 0.000000e+00, %6 ], [ %386, %115 ]
  %145 = phi float [ 0.000000e+00, %6 ], [ %387, %115 ]
  %146 = phi float [ 0.000000e+00, %6 ], [ %388, %115 ]
  %147 = phi float [ 0.000000e+00, %6 ], [ %389, %115 ]
  %148 = phi float [ 0.000000e+00, %6 ], [ %390, %115 ]
  %149 = phi float [ 0.000000e+00, %6 ], [ %391, %115 ]
  %150 = phi float [ 0.000000e+00, %6 ], [ %392, %115 ]
  %151 = phi float [ 0.000000e+00, %6 ], [ %285, %115 ]
  %152 = phi float [ 0.000000e+00, %6 ], [ %286, %115 ]
  %153 = phi float [ 0.000000e+00, %6 ], [ %287, %115 ]
  %154 = phi float [ 0.000000e+00, %6 ], [ %288, %115 ]
  %155 = phi float [ 0.000000e+00, %6 ], [ %289, %115 ]
  %156 = phi float [ 0.000000e+00, %6 ], [ %290, %115 ]
  %157 = phi float [ 0.000000e+00, %6 ], [ %291, %115 ]
  %158 = phi float [ 0.000000e+00, %6 ], [ %292, %115 ]
  %159 = phi float [ 0.000000e+00, %6 ], [ %293, %115 ]
  %160 = phi float [ 0.000000e+00, %6 ], [ %294, %115 ]
  %161 = phi float [ 0.000000e+00, %6 ], [ %295, %115 ]
  %162 = phi float [ 0.000000e+00, %6 ], [ %296, %115 ]
  %163 = phi float [ 0.000000e+00, %6 ], [ %297, %115 ]
  %164 = phi float [ 0.000000e+00, %6 ], [ %298, %115 ]
  %165 = phi float [ 0.000000e+00, %6 ], [ %299, %115 ]
  %166 = phi float [ 0.000000e+00, %6 ], [ %300, %115 ]
  %167 = phi float [ 0.000000e+00, %6 ], [ %301, %115 ]
  %168 = phi float [ 0.000000e+00, %6 ], [ %302, %115 ]
  %169 = phi float [ 0.000000e+00, %6 ], [ %303, %115 ]
  %170 = phi float [ 0.000000e+00, %6 ], [ %304, %115 ]
  %171 = phi float [ 0.000000e+00, %6 ], [ %305, %115 ]
  %172 = phi float [ 0.000000e+00, %6 ], [ %306, %115 ]
  %173 = phi float [ 0.000000e+00, %6 ], [ %307, %115 ]
  %174 = phi float [ 0.000000e+00, %6 ], [ %308, %115 ]
  %175 = phi float [ 0.000000e+00, %6 ], [ %309, %115 ]
  %176 = phi float [ 0.000000e+00, %6 ], [ %310, %115 ]
  %177 = phi float [ 0.000000e+00, %6 ], [ %311, %115 ]
  %178 = phi float [ 0.000000e+00, %6 ], [ %312, %115 ]
  %179 = phi float [ 0.000000e+00, %6 ], [ %313, %115 ]
  %180 = phi float [ 0.000000e+00, %6 ], [ %314, %115 ]
  %181 = phi float [ 0.000000e+00, %6 ], [ %315, %115 ]
  %182 = phi float [ 0.000000e+00, %6 ], [ %316, %115 ]
  %183 = icmp samesign ult i64 %indvars.iv, 8096, !dbg !22
  %184 = add i32 %117, 1, !dbg !22
  %185 = icmp sgt i32 %184, 3, !dbg !22
  %186 = select i1 %185, i32 0, i32 %184, !dbg !22
  %187 = zext i1 %185 to i32, !dbg !22
  %188 = xor i32 %116, %187, !dbg !22
  %189 = or disjoint i64 %indvars.iv, %106, !dbg !25
  %190 = getelementptr i64, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43008), i32 %186, !dbg !22
  tail call void asm sideeffect "\0A{\0A\09.reg .pred complete;\0A\09waitLoop:\0A\09mbarrier.try_wait.parity.shared.b64 complete, [$0], $1;\0A\09@!complete bra.uni waitLoop;\0A}\0A", "r,r"(ptr addrspace(3) %190, i32 %188) #6, !dbg !22
  %.idx = shl i32 %186, 13, !dbg !23
  %191 = getelementptr i8, ptr addrspace(3) @global_smem, i32 %.idx, !dbg !23
  %gep = getelementptr bfloat, ptr addrspace(1) %invariant.gep, i64 %189, !dbg !26
  %gep132 = getelementptr bfloat, ptr addrspace(1) %invariant.gep131, i64 %189, !dbg !26
  %gep134 = getelementptr bfloat, ptr addrspace(1) %invariant.gep133, i64 %189, !dbg !26
  %gep136 = getelementptr bfloat, ptr addrspace(1) %invariant.gep135, i64 %189, !dbg !26
  %gep138 = getelementptr bfloat, ptr addrspace(1) %invariant.gep137, i64 %189, !dbg !26
  %gep140 = getelementptr bfloat, ptr addrspace(1) %invariant.gep139, i64 %189, !dbg !26
  %gep142 = getelementptr bfloat, ptr addrspace(1) %invariant.gep141, i64 %189, !dbg !26
  %gep144 = getelementptr bfloat, ptr addrspace(1) %invariant.gep143, i64 %189, !dbg !26
  %192 = tail call i16 asm sideeffect "mov.u16 $0, 0x0;\0A\09ld.global.b16 { $0 }, [ $1 + 0 ];", "=c,l"(ptr addrspace(1) %gep) #6, !dbg !27
  %193 = tail call i16 asm sideeffect "mov.u16 $0, 0x0;\0A\09ld.global.b16 { $0 }, [ $1 + 0 ];", "=c,l"(ptr addrspace(1) %gep132) #6, !dbg !27
  %194 = tail call i16 asm sideeffect "mov.u16 $0, 0x0;\0A\09ld.global.b16 { $0 }, [ $1 + 0 ];", "=c,l"(ptr addrspace(1) %gep134) #6, !dbg !27
  %195 = tail call i16 asm sideeffect "mov.u16 $0, 0x0;\0A\09ld.global.b16 { $0 }, [ $1 + 0 ];", "=c,l"(ptr addrspace(1) %gep136) #6, !dbg !27
  %196 = tail call i16 asm sideeffect "mov.u16 $0, 0x0;\0A\09ld.global.b16 { $0 }, [ $1 + 0 ];", "=c,l"(ptr addrspace(1) %gep138) #6, !dbg !27
  %197 = tail call i16 asm sideeffect "mov.u16 $0, 0x0;\0A\09ld.global.b16 { $0 }, [ $1 + 0 ];", "=c,l"(ptr addrspace(1) %gep140) #6, !dbg !27
  %198 = tail call i16 asm sideeffect "mov.u16 $0, 0x0;\0A\09ld.global.b16 { $0 }, [ $1 + 0 ];", "=c,l"(ptr addrspace(1) %gep142) #6, !dbg !27
  %199 = tail call i16 asm sideeffect "mov.u16 $0, 0x0;\0A\09ld.global.b16 { $0 }, [ $1 + 0 ];", "=c,l"(ptr addrspace(1) %gep144) #6, !dbg !27
  %200 = insertelement <1 x i16> poison, i16 %192, i64 0, !dbg !28
  store <1 x i16> %200, ptr addrspace(3) %92, align 2, !dbg !28
  %201 = insertelement <1 x i16> poison, i16 %194, i64 0, !dbg !28
  store <1 x i16> %201, ptr addrspace(3) %93, align 2, !dbg !28
  %202 = insertelement <1 x i16> poison, i16 %196, i64 0, !dbg !28
  store <1 x i16> %202, ptr addrspace(3) %94, align 2, !dbg !28
  %203 = insertelement <1 x i16> poison, i16 %198, i64 0, !dbg !28
  store <1 x i16> %203, ptr addrspace(3) %95, align 2, !dbg !28
  %204 = insertelement <1 x i16> poison, i16 %193, i64 0, !dbg !28
  store <1 x i16> %204, ptr addrspace(3) %97, align 2, !dbg !28
  %205 = insertelement <1 x i16> poison, i16 %195, i64 0, !dbg !28
  store <1 x i16> %205, ptr addrspace(3) %98, align 2, !dbg !28
  %206 = insertelement <1 x i16> poison, i16 %197, i64 0, !dbg !28
  store <1 x i16> %206, ptr addrspace(3) %99, align 2, !dbg !28
  %207 = insertelement <1 x i16> poison, i16 %199, i64 0, !dbg !28
  store <1 x i16> %207, ptr addrspace(3) %100, align 2, !dbg !28
  tail call void asm sideeffect "fence.proxy.async.shared::cta;", ""() #6, !dbg !29
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !29
  %208 = ptrtoint ptr addrspace(3) %191 to i32, !dbg !29
  %209 = lshr exact i32 %208, 4, !dbg !29
  %210 = and i32 %209, 16383, !dbg !29
  %211 = zext nneg i32 %210 to i64, !dbg !29
  tail call void @llvm.nvvm.wgmma.fence.sync.aligned(), !dbg !29
  %212 = or disjoint i64 %211, -9223371899415822336, !dbg !29
  %213 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "wgmma.mma_async.sync.aligned.m64n32k16.f32.bf16.bf16 {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}, $32, $33, $34, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,l,l,b"(float %151, float %152, float %153, float %154, float %155, float %156, float %157, float %158, float %159, float %160, float %161, float %162, float %163, float %164, float %165, float %166, i64 %212, i64 %104, i1 true) #6, !dbg !29
  %214 = add nuw nsw i64 %211, -9223371899415822334, !dbg !29
  %215 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 0, !dbg !29
  %216 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 1, !dbg !29
  %217 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 2, !dbg !29
  %218 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 3, !dbg !29
  %219 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 4, !dbg !29
  %220 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 5, !dbg !29
  %221 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 6, !dbg !29
  %222 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 7, !dbg !29
  %223 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 8, !dbg !29
  %224 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 9, !dbg !29
  %225 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 10, !dbg !29
  %226 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 11, !dbg !29
  %227 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 12, !dbg !29
  %228 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 13, !dbg !29
  %229 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 14, !dbg !29
  %230 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %213, 15, !dbg !29
  %231 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "wgmma.mma_async.sync.aligned.m64n32k16.f32.bf16.bf16 {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}, $32, $33, $34, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,l,l,b"(float %215, float %216, float %217, float %218, float %219, float %220, float %221, float %222, float %223, float %224, float %225, float %226, float %227, float %228, float %229, float %230, i64 %214, i64 %105, i1 true) #6, !dbg !29
  %232 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 0, !dbg !29
  %233 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 1, !dbg !29
  %234 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 2, !dbg !29
  %235 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 3, !dbg !29
  %236 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 4, !dbg !29
  %237 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 5, !dbg !29
  %238 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 6, !dbg !29
  %239 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 7, !dbg !29
  %240 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 8, !dbg !29
  %241 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 9, !dbg !29
  %242 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 10, !dbg !29
  %243 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 11, !dbg !29
  %244 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 12, !dbg !29
  %245 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 13, !dbg !29
  %246 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 14, !dbg !29
  %247 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %231, 15, !dbg !29
  %248 = add nuw nsw i64 %211, -9223371899415822080, !dbg !29
  %249 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "wgmma.mma_async.sync.aligned.m64n32k16.f32.bf16.bf16 {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}, $32, $33, $34, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,l,l,b"(float %167, float %168, float %169, float %170, float %171, float %172, float %173, float %174, float %175, float %176, float %177, float %178, float %179, float %180, float %181, float %182, i64 %248, i64 %104, i1 true) #6, !dbg !29
  %250 = add nuw nsw i64 %211, -9223371899415822078, !dbg !29
  %251 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 0, !dbg !29
  %252 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 1, !dbg !29
  %253 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 2, !dbg !29
  %254 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 3, !dbg !29
  %255 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 4, !dbg !29
  %256 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 5, !dbg !29
  %257 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 6, !dbg !29
  %258 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 7, !dbg !29
  %259 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 8, !dbg !29
  %260 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 9, !dbg !29
  %261 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 10, !dbg !29
  %262 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 11, !dbg !29
  %263 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 12, !dbg !29
  %264 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 13, !dbg !29
  %265 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 14, !dbg !29
  %266 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %249, 15, !dbg !29
  %267 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "wgmma.mma_async.sync.aligned.m64n32k16.f32.bf16.bf16 {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}, $32, $33, $34, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,l,l,b"(float %251, float %252, float %253, float %254, float %255, float %256, float %257, float %258, float %259, float %260, float %261, float %262, float %263, float %264, float %265, float %266, i64 %250, i64 %105, i1 true) #6, !dbg !29
  %268 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 0, !dbg !29
  %269 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 1, !dbg !29
  %270 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 2, !dbg !29
  %271 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 3, !dbg !29
  %272 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 4, !dbg !29
  %273 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 5, !dbg !29
  %274 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 6, !dbg !29
  %275 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 7, !dbg !29
  %276 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 8, !dbg !29
  %277 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 9, !dbg !29
  %278 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 10, !dbg !29
  %279 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 11, !dbg !29
  %280 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 12, !dbg !29
  %281 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 13, !dbg !29
  %282 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 14, !dbg !29
  %283 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %267, 15, !dbg !29
  tail call void @llvm.nvvm.wgmma.commit_group.sync.aligned(), !dbg !29
  %284 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } asm sideeffect "// wait for regs: $0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37\0A\09wgmma.wait_group.sync.aligned 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=l,=r,=r,=l,=r,=r,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37"(float %232, float %233, float %234, float %235, float %236, float %237, float %238, float %239, float %240, float %241, float %242, float %243, float %244, float %245, float %246, float %247, float %268, float %269, float %270, float %271, float %272, float %273, float %274, float %275, float %276, float %277, float %278, float %279, float %280, float %281, float %282, float %283, ptr addrspace(3) %191, i32 0, i32 0, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 40960), i32 0, i32 0) #6, !dbg !29
  %285 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 0, !dbg !29
  %286 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 1, !dbg !29
  %287 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 2, !dbg !29
  %288 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 3, !dbg !29
  %289 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 4, !dbg !29
  %290 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 5, !dbg !29
  %291 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 6, !dbg !29
  %292 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 7, !dbg !29
  %293 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 8, !dbg !29
  %294 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 9, !dbg !29
  %295 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 10, !dbg !29
  %296 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 11, !dbg !29
  %297 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 12, !dbg !29
  %298 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 13, !dbg !29
  %299 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 14, !dbg !29
  %300 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 15, !dbg !29
  %301 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 16, !dbg !29
  %302 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 17, !dbg !29
  %303 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 18, !dbg !29
  %304 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 19, !dbg !29
  %305 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 20, !dbg !29
  %306 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 21, !dbg !29
  %307 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 22, !dbg !29
  %308 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 23, !dbg !29
  %309 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 24, !dbg !29
  %310 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 25, !dbg !29
  %311 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 26, !dbg !29
  %312 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 27, !dbg !29
  %313 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 28, !dbg !29
  %314 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 29, !dbg !29
  %315 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 30, !dbg !29
  %316 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, ptr addrspace(3), i32, i32, ptr addrspace(3), i32, i32 } %284, 31, !dbg !29
  %317 = getelementptr i64, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43040), i32 %186, !dbg !22
  tail call void asm sideeffect "\0A{\0A\09.reg .pred complete;\0A\09waitLoop:\0A\09mbarrier.try_wait.parity.shared.b64 complete, [$0], $1;\0A\09@!complete bra.uni waitLoop;\0A}\0A", "r,r"(ptr addrspace(3) %317, i32 %188) #6, !dbg !22
  %.idx1 = shl i32 %186, 11, !dbg !24
  %318 = getelementptr i8, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 32768), i32 %.idx1, !dbg !24
  %319 = ptrtoint ptr addrspace(3) %318 to i32, !dbg !30
  %320 = lshr exact i32 %319, 4, !dbg !30
  %321 = and i32 %320, 16383, !dbg !30
  %322 = zext nneg i32 %321 to i64, !dbg !30
  tail call void @llvm.nvvm.wgmma.fence.sync.aligned(), !dbg !30
  %323 = or disjoint i64 %322, -9223371899415822336, !dbg !30
  %324 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "wgmma.mma_async.sync.aligned.m64n32k16.f32.bf16.bf16 {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}, $32, $33, $34, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,l,l,b"(float %119, float %120, float %121, float %122, float %123, float %124, float %125, float %126, float %127, float %128, float %129, float %130, float %131, float %132, float %133, float %134, i64 %212, i64 %323, i1 true) #6, !dbg !30
  %325 = add nuw nsw i64 %322, -9223371899415822334, !dbg !30
  %326 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 0, !dbg !30
  %327 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 1, !dbg !30
  %328 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 2, !dbg !30
  %329 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 3, !dbg !30
  %330 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 4, !dbg !30
  %331 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 5, !dbg !30
  %332 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 6, !dbg !30
  %333 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 7, !dbg !30
  %334 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 8, !dbg !30
  %335 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 9, !dbg !30
  %336 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 10, !dbg !30
  %337 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 11, !dbg !30
  %338 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 12, !dbg !30
  %339 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 13, !dbg !30
  %340 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 14, !dbg !30
  %341 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %324, 15, !dbg !30
  %342 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "wgmma.mma_async.sync.aligned.m64n32k16.f32.bf16.bf16 {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}, $32, $33, $34, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,l,l,b"(float %326, float %327, float %328, float %329, float %330, float %331, float %332, float %333, float %334, float %335, float %336, float %337, float %338, float %339, float %340, float %341, i64 %214, i64 %325, i1 true) #6, !dbg !30
  %343 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 0, !dbg !30
  %344 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 1, !dbg !30
  %345 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 2, !dbg !30
  %346 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 3, !dbg !30
  %347 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 4, !dbg !30
  %348 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 5, !dbg !30
  %349 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 6, !dbg !30
  %350 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 7, !dbg !30
  %351 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 8, !dbg !30
  %352 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 9, !dbg !30
  %353 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 10, !dbg !30
  %354 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 11, !dbg !30
  %355 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 12, !dbg !30
  %356 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 13, !dbg !30
  %357 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 14, !dbg !30
  %358 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %342, 15, !dbg !30
  %359 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "wgmma.mma_async.sync.aligned.m64n32k16.f32.bf16.bf16 {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}, $32, $33, $34, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,l,l,b"(float %135, float %136, float %137, float %138, float %139, float %140, float %141, float %142, float %143, float %144, float %145, float %146, float %147, float %148, float %149, float %150, i64 %248, i64 %323, i1 true) #6, !dbg !30
  %360 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 0, !dbg !30
  %361 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 1, !dbg !30
  %362 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 2, !dbg !30
  %363 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 3, !dbg !30
  %364 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 4, !dbg !30
  %365 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 5, !dbg !30
  %366 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 6, !dbg !30
  %367 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 7, !dbg !30
  %368 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 8, !dbg !30
  %369 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 9, !dbg !30
  %370 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 10, !dbg !30
  %371 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 11, !dbg !30
  %372 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 12, !dbg !30
  %373 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 13, !dbg !30
  %374 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 14, !dbg !30
  %375 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %359, 15, !dbg !30
  %376 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "wgmma.mma_async.sync.aligned.m64n32k16.f32.bf16.bf16 {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}, $32, $33, $34, 1, 1, 0, 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,l,l,b"(float %360, float %361, float %362, float %363, float %364, float %365, float %366, float %367, float %368, float %369, float %370, float %371, float %372, float %373, float %374, float %375, i64 %250, i64 %325, i1 true) #6, !dbg !30
  %377 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 0, !dbg !30
  %378 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 1, !dbg !30
  %379 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 2, !dbg !30
  %380 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 3, !dbg !30
  %381 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 4, !dbg !30
  %382 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 5, !dbg !30
  %383 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 6, !dbg !30
  %384 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 7, !dbg !30
  %385 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 8, !dbg !30
  %386 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 9, !dbg !30
  %387 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 10, !dbg !30
  %388 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 11, !dbg !30
  %389 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 12, !dbg !30
  %390 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 13, !dbg !30
  %391 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 14, !dbg !30
  %392 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %376, 15, !dbg !30
  tail call void @llvm.nvvm.wgmma.commit_group.sync.aligned(), !dbg !30
  %393 = add i32 %118, 1, !dbg !22
  %394 = icmp sgt i32 %393, 3, !dbg !22
  %395 = select i1 %394, i32 0, i32 %393, !dbg !22
  %396 = getelementptr i64, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43008), i32 %395, !dbg !22
  %397 = and i1 %23, %183, !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.arrive.expect_tx.shared.b64 _, [$1], 8192;", "b,r"(i1 %397, ptr addrspace(3) %396) #6, !dbg !22
  %.idx2 = shl i32 %395, 13, !dbg !23
  %398 = getelementptr i8, ptr addrspace(3) @global_smem, i32 %.idx2, !dbg !23
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !23
  %399 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !23
  %400 = extractvalue { i32, i1 } %399, 1, !dbg !23
  %401 = and i1 %183, %400, !dbg !23
  %402 = and i1 %21, %401, !dbg !23
  %403 = trunc nuw nsw i64 %indvars.iv to i32, !dbg !23
  %404 = add nuw nsw i32 %403, 96, !dbg !23
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [$1], [$2, {$3, $4}], [$5];", "b,r,l,r,r,r"(i1 %402, ptr addrspace(3) %398, ptr %24, i32 %404, i32 %40, ptr addrspace(3) %396) #6, !dbg !23
  %405 = getelementptr i64, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43040), i32 %395, !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.arrive.expect_tx.shared.b64 _, [$1], 2048;", "b,r"(i1 %397, ptr addrspace(3) %405) #6, !dbg !22
  %.idx3 = shl i32 %395, 11, !dbg !24
  %406 = getelementptr i8, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 32768), i32 %.idx3, !dbg !24
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !24
  %407 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !24
  %408 = extractvalue { i32, i1 } %407, 1, !dbg !24
  %409 = and i1 %183, %408, !dbg !24
  %410 = and i1 %21, %409, !dbg !24
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes [$1], [$2, {$3, $4}], [$5];", "b,r,l,r,r,r"(i1 %410, ptr addrspace(3) %406, ptr %28, i32 %404, i32 %41, ptr addrspace(3) %405) #6, !dbg !24
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 32, !dbg !22
  %411 = icmp samesign ult i64 %indvars.iv, 8160, !dbg !22
  br i1 %411, label %115, label %412, !dbg !22

412:                                              ; preds = %115
  %413 = addrspacecast ptr addrspace(1) %31 to ptr, !dbg !9
  %414 = tail call { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } asm sideeffect "// wait for regs: $0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31\0A\09wgmma.wait_group.sync.aligned 0;", "=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,=f,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31"(float %343, float %344, float %345, float %346, float %347, float %348, float %349, float %350, float %351, float %352, float %353, float %354, float %355, float %356, float %357, float %358, float %377, float %378, float %379, float %380, float %381, float %382, float %383, float %384, float %385, float %386, float %387, float %388, float %389, float %390, float %391, float %392) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.inval.shared::cta.b64 [$1];", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43040)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.inval.shared::cta.b64 [$1];", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43048)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.inval.shared::cta.b64 [$1];", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43056)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.inval.shared::cta.b64 [$1];", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43064)) #6, !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.inval.shared::cta.b64 [$1];", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43008)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.inval.shared::cta.b64 [$1];", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43016)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.inval.shared::cta.b64 [$1];", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43024)) #6, !dbg !22
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !22
  tail call void asm sideeffect "@$0 mbarrier.inval.shared::cta.b64 [$1];", "b,r"(i1 %23, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i32 43032)) #6, !dbg !22
  %415 = fsub float 0.000000e+00, %285, !dbg !31
  %416 = fsub float 0.000000e+00, %286, !dbg !31
  %417 = fsub float 0.000000e+00, %287, !dbg !31
  %418 = fsub float 0.000000e+00, %288, !dbg !31
  %419 = fsub float 0.000000e+00, %289, !dbg !31
  %420 = fsub float 0.000000e+00, %290, !dbg !31
  %421 = fsub float 0.000000e+00, %291, !dbg !31
  %422 = fsub float 0.000000e+00, %292, !dbg !31
  %423 = fsub float 0.000000e+00, %293, !dbg !31
  %424 = fsub float 0.000000e+00, %294, !dbg !31
  %425 = fsub float 0.000000e+00, %295, !dbg !31
  %426 = fsub float 0.000000e+00, %296, !dbg !31
  %427 = fsub float 0.000000e+00, %297, !dbg !31
  %428 = fsub float 0.000000e+00, %298, !dbg !31
  %429 = fsub float 0.000000e+00, %299, !dbg !31
  %430 = fsub float 0.000000e+00, %300, !dbg !31
  %431 = fsub float 0.000000e+00, %301, !dbg !31
  %432 = fsub float 0.000000e+00, %302, !dbg !31
  %433 = fsub float 0.000000e+00, %303, !dbg !31
  %434 = fsub float 0.000000e+00, %304, !dbg !31
  %435 = fsub float 0.000000e+00, %305, !dbg !31
  %436 = fsub float 0.000000e+00, %306, !dbg !31
  %437 = fsub float 0.000000e+00, %307, !dbg !31
  %438 = fsub float 0.000000e+00, %308, !dbg !31
  %439 = fsub float 0.000000e+00, %309, !dbg !31
  %440 = fsub float 0.000000e+00, %310, !dbg !31
  %441 = fsub float 0.000000e+00, %311, !dbg !31
  %442 = fsub float 0.000000e+00, %312, !dbg !31
  %443 = fsub float 0.000000e+00, %313, !dbg !31
  %444 = fsub float 0.000000e+00, %314, !dbg !31
  %445 = fsub float 0.000000e+00, %315, !dbg !31
  %446 = fsub float 0.000000e+00, %316, !dbg !31
  %447 = fmul float %415, 0x3FF7154760000000, !dbg !36
  %448 = tail call float @llvm.nvvm.ex2.approx.f(float %447), !dbg !36
  %449 = fmul float %416, 0x3FF7154760000000, !dbg !36
  %450 = tail call float @llvm.nvvm.ex2.approx.f(float %449), !dbg !36
  %451 = fmul float %417, 0x3FF7154760000000, !dbg !36
  %452 = tail call float @llvm.nvvm.ex2.approx.f(float %451), !dbg !36
  %453 = fmul float %418, 0x3FF7154760000000, !dbg !36
  %454 = tail call float @llvm.nvvm.ex2.approx.f(float %453), !dbg !36
  %455 = fmul float %419, 0x3FF7154760000000, !dbg !36
  %456 = tail call float @llvm.nvvm.ex2.approx.f(float %455), !dbg !36
  %457 = fmul float %420, 0x3FF7154760000000, !dbg !36
  %458 = tail call float @llvm.nvvm.ex2.approx.f(float %457), !dbg !36
  %459 = fmul float %421, 0x3FF7154760000000, !dbg !36
  %460 = tail call float @llvm.nvvm.ex2.approx.f(float %459), !dbg !36
  %461 = fmul float %422, 0x3FF7154760000000, !dbg !36
  %462 = tail call float @llvm.nvvm.ex2.approx.f(float %461), !dbg !36
  %463 = fmul float %423, 0x3FF7154760000000, !dbg !36
  %464 = tail call float @llvm.nvvm.ex2.approx.f(float %463), !dbg !36
  %465 = fmul float %424, 0x3FF7154760000000, !dbg !36
  %466 = tail call float @llvm.nvvm.ex2.approx.f(float %465), !dbg !36
  %467 = fmul float %425, 0x3FF7154760000000, !dbg !36
  %468 = tail call float @llvm.nvvm.ex2.approx.f(float %467), !dbg !36
  %469 = fmul float %426, 0x3FF7154760000000, !dbg !36
  %470 = tail call float @llvm.nvvm.ex2.approx.f(float %469), !dbg !36
  %471 = fmul float %427, 0x3FF7154760000000, !dbg !36
  %472 = tail call float @llvm.nvvm.ex2.approx.f(float %471), !dbg !36
  %473 = fmul float %428, 0x3FF7154760000000, !dbg !36
  %474 = tail call float @llvm.nvvm.ex2.approx.f(float %473), !dbg !36
  %475 = fmul float %429, 0x3FF7154760000000, !dbg !36
  %476 = tail call float @llvm.nvvm.ex2.approx.f(float %475), !dbg !36
  %477 = fmul float %430, 0x3FF7154760000000, !dbg !36
  %478 = tail call float @llvm.nvvm.ex2.approx.f(float %477), !dbg !36
  %479 = fmul float %431, 0x3FF7154760000000, !dbg !36
  %480 = tail call float @llvm.nvvm.ex2.approx.f(float %479), !dbg !36
  %481 = fmul float %432, 0x3FF7154760000000, !dbg !36
  %482 = tail call float @llvm.nvvm.ex2.approx.f(float %481), !dbg !36
  %483 = fmul float %433, 0x3FF7154760000000, !dbg !36
  %484 = tail call float @llvm.nvvm.ex2.approx.f(float %483), !dbg !36
  %485 = fmul float %434, 0x3FF7154760000000, !dbg !36
  %486 = tail call float @llvm.nvvm.ex2.approx.f(float %485), !dbg !36
  %487 = fmul float %435, 0x3FF7154760000000, !dbg !36
  %488 = tail call float @llvm.nvvm.ex2.approx.f(float %487), !dbg !36
  %489 = fmul float %436, 0x3FF7154760000000, !dbg !36
  %490 = tail call float @llvm.nvvm.ex2.approx.f(float %489), !dbg !36
  %491 = fmul float %437, 0x3FF7154760000000, !dbg !36
  %492 = tail call float @llvm.nvvm.ex2.approx.f(float %491), !dbg !36
  %493 = fmul float %438, 0x3FF7154760000000, !dbg !36
  %494 = tail call float @llvm.nvvm.ex2.approx.f(float %493), !dbg !36
  %495 = fmul float %439, 0x3FF7154760000000, !dbg !36
  %496 = tail call float @llvm.nvvm.ex2.approx.f(float %495), !dbg !36
  %497 = fmul float %440, 0x3FF7154760000000, !dbg !36
  %498 = tail call float @llvm.nvvm.ex2.approx.f(float %497), !dbg !36
  %499 = fmul float %441, 0x3FF7154760000000, !dbg !36
  %500 = tail call float @llvm.nvvm.ex2.approx.f(float %499), !dbg !36
  %501 = fmul float %442, 0x3FF7154760000000, !dbg !36
  %502 = tail call float @llvm.nvvm.ex2.approx.f(float %501), !dbg !36
  %503 = fmul float %443, 0x3FF7154760000000, !dbg !36
  %504 = tail call float @llvm.nvvm.ex2.approx.f(float %503), !dbg !36
  %505 = fmul float %444, 0x3FF7154760000000, !dbg !36
  %506 = tail call float @llvm.nvvm.ex2.approx.f(float %505), !dbg !36
  %507 = fmul float %445, 0x3FF7154760000000, !dbg !36
  %508 = tail call float @llvm.nvvm.ex2.approx.f(float %507), !dbg !36
  %509 = fmul float %446, 0x3FF7154760000000, !dbg !36
  %510 = tail call float @llvm.nvvm.ex2.approx.f(float %509), !dbg !36
  %511 = fadd float %448, 1.000000e+00, !dbg !37
  %512 = fadd float %450, 1.000000e+00, !dbg !37
  %513 = fadd float %452, 1.000000e+00, !dbg !37
  %514 = fadd float %454, 1.000000e+00, !dbg !37
  %515 = fadd float %456, 1.000000e+00, !dbg !37
  %516 = fadd float %458, 1.000000e+00, !dbg !37
  %517 = fadd float %460, 1.000000e+00, !dbg !37
  %518 = fadd float %462, 1.000000e+00, !dbg !37
  %519 = fadd float %464, 1.000000e+00, !dbg !37
  %520 = fadd float %466, 1.000000e+00, !dbg !37
  %521 = fadd float %468, 1.000000e+00, !dbg !37
  %522 = fadd float %470, 1.000000e+00, !dbg !37
  %523 = fadd float %472, 1.000000e+00, !dbg !37
  %524 = fadd float %474, 1.000000e+00, !dbg !37
  %525 = fadd float %476, 1.000000e+00, !dbg !37
  %526 = fadd float %478, 1.000000e+00, !dbg !37
  %527 = fadd float %480, 1.000000e+00, !dbg !37
  %528 = fadd float %482, 1.000000e+00, !dbg !37
  %529 = fadd float %484, 1.000000e+00, !dbg !37
  %530 = fadd float %486, 1.000000e+00, !dbg !37
  %531 = fadd float %488, 1.000000e+00, !dbg !37
  %532 = fadd float %490, 1.000000e+00, !dbg !37
  %533 = fadd float %492, 1.000000e+00, !dbg !37
  %534 = fadd float %494, 1.000000e+00, !dbg !37
  %535 = fadd float %496, 1.000000e+00, !dbg !37
  %536 = fadd float %498, 1.000000e+00, !dbg !37
  %537 = fadd float %500, 1.000000e+00, !dbg !37
  %538 = fadd float %502, 1.000000e+00, !dbg !37
  %539 = fadd float %504, 1.000000e+00, !dbg !37
  %540 = fadd float %506, 1.000000e+00, !dbg !37
  %541 = fadd float %508, 1.000000e+00, !dbg !37
  %542 = fadd float %510, 1.000000e+00, !dbg !37
  %543 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %511), !dbg !38
  %544 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %512), !dbg !38
  %545 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %513), !dbg !38
  %546 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %514), !dbg !38
  %547 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %515), !dbg !38
  %548 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %516), !dbg !38
  %549 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %517), !dbg !38
  %550 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %518), !dbg !38
  %551 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %519), !dbg !38
  %552 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %520), !dbg !38
  %553 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %521), !dbg !38
  %554 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %522), !dbg !38
  %555 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %523), !dbg !38
  %556 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %524), !dbg !38
  %557 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %525), !dbg !38
  %558 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %526), !dbg !38
  %559 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %527), !dbg !38
  %560 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %528), !dbg !38
  %561 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %529), !dbg !38
  %562 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %530), !dbg !38
  %563 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %531), !dbg !38
  %564 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %532), !dbg !38
  %565 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %533), !dbg !38
  %566 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %534), !dbg !38
  %567 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %535), !dbg !38
  %568 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %536), !dbg !38
  %569 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %537), !dbg !38
  %570 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %538), !dbg !38
  %571 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %539), !dbg !38
  %572 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %540), !dbg !38
  %573 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %541), !dbg !38
  %574 = tail call float @llvm.nvvm.div.full(float 1.000000e+00, float %542), !dbg !38
  %575 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 0, !dbg !39
  %576 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 1, !dbg !39
  %577 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 2, !dbg !39
  %578 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 3, !dbg !39
  %579 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 4, !dbg !39
  %580 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 5, !dbg !39
  %581 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 6, !dbg !39
  %582 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 7, !dbg !39
  %583 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 8, !dbg !39
  %584 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 9, !dbg !39
  %585 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 10, !dbg !39
  %586 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 11, !dbg !39
  %587 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 12, !dbg !39
  %588 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 13, !dbg !39
  %589 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 14, !dbg !39
  %590 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 15, !dbg !39
  %591 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 16, !dbg !39
  %592 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 17, !dbg !39
  %593 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 18, !dbg !39
  %594 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 19, !dbg !39
  %595 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 20, !dbg !39
  %596 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 21, !dbg !39
  %597 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 22, !dbg !39
  %598 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 23, !dbg !39
  %599 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 24, !dbg !39
  %600 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 25, !dbg !39
  %601 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 26, !dbg !39
  %602 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 27, !dbg !39
  %603 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 28, !dbg !39
  %604 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 29, !dbg !39
  %605 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 30, !dbg !39
  %606 = extractvalue { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } %414, 31, !dbg !39
  %607 = insertelement <2 x float> poison, float %285, i64 0, !dbg !40
  %608 = insertelement <2 x float> %607, float %286, i64 1, !dbg !40
  %609 = insertelement <2 x float> poison, float %543, i64 0, !dbg !40
  %610 = insertelement <2 x float> %609, float %544, i64 1, !dbg !40
  %611 = fmul <2 x float> %608, %610, !dbg !40
  %612 = insertelement <2 x float> poison, float %575, i64 0, !dbg !39
  %613 = insertelement <2 x float> %612, float %576, i64 1, !dbg !39
  %614 = fmul <2 x float> %613, %611, !dbg !39
  %615 = fptrunc <2 x float> %614 to <2 x bfloat>, !dbg !41
  %616 = insertelement <2 x float> poison, float %287, i64 0, !dbg !40
  %617 = insertelement <2 x float> %616, float %288, i64 1, !dbg !40
  %618 = insertelement <2 x float> poison, float %545, i64 0, !dbg !40
  %619 = insertelement <2 x float> %618, float %546, i64 1, !dbg !40
  %620 = fmul <2 x float> %617, %619, !dbg !40
  %621 = insertelement <2 x float> poison, float %577, i64 0, !dbg !39
  %622 = insertelement <2 x float> %621, float %578, i64 1, !dbg !39
  %623 = fmul <2 x float> %622, %620, !dbg !39
  %624 = fptrunc <2 x float> %623 to <2 x bfloat>, !dbg !41
  %625 = insertelement <2 x float> poison, float %289, i64 0, !dbg !40
  %626 = insertelement <2 x float> %625, float %290, i64 1, !dbg !40
  %627 = insertelement <2 x float> poison, float %547, i64 0, !dbg !40
  %628 = insertelement <2 x float> %627, float %548, i64 1, !dbg !40
  %629 = fmul <2 x float> %626, %628, !dbg !40
  %630 = insertelement <2 x float> poison, float %579, i64 0, !dbg !39
  %631 = insertelement <2 x float> %630, float %580, i64 1, !dbg !39
  %632 = fmul <2 x float> %631, %629, !dbg !39
  %633 = fptrunc <2 x float> %632 to <2 x bfloat>, !dbg !41
  %634 = insertelement <2 x float> poison, float %291, i64 0, !dbg !40
  %635 = insertelement <2 x float> %634, float %292, i64 1, !dbg !40
  %636 = insertelement <2 x float> poison, float %549, i64 0, !dbg !40
  %637 = insertelement <2 x float> %636, float %550, i64 1, !dbg !40
  %638 = fmul <2 x float> %635, %637, !dbg !40
  %639 = insertelement <2 x float> poison, float %581, i64 0, !dbg !39
  %640 = insertelement <2 x float> %639, float %582, i64 1, !dbg !39
  %641 = fmul <2 x float> %640, %638, !dbg !39
  %642 = fptrunc <2 x float> %641 to <2 x bfloat>, !dbg !41
  %643 = insertelement <2 x float> poison, float %293, i64 0, !dbg !40
  %644 = insertelement <2 x float> %643, float %294, i64 1, !dbg !40
  %645 = insertelement <2 x float> poison, float %551, i64 0, !dbg !40
  %646 = insertelement <2 x float> %645, float %552, i64 1, !dbg !40
  %647 = fmul <2 x float> %644, %646, !dbg !40
  %648 = insertelement <2 x float> poison, float %583, i64 0, !dbg !39
  %649 = insertelement <2 x float> %648, float %584, i64 1, !dbg !39
  %650 = fmul <2 x float> %649, %647, !dbg !39
  %651 = fptrunc <2 x float> %650 to <2 x bfloat>, !dbg !41
  %652 = insertelement <2 x float> poison, float %295, i64 0, !dbg !40
  %653 = insertelement <2 x float> %652, float %296, i64 1, !dbg !40
  %654 = insertelement <2 x float> poison, float %553, i64 0, !dbg !40
  %655 = insertelement <2 x float> %654, float %554, i64 1, !dbg !40
  %656 = fmul <2 x float> %653, %655, !dbg !40
  %657 = insertelement <2 x float> poison, float %585, i64 0, !dbg !39
  %658 = insertelement <2 x float> %657, float %586, i64 1, !dbg !39
  %659 = fmul <2 x float> %658, %656, !dbg !39
  %660 = fptrunc <2 x float> %659 to <2 x bfloat>, !dbg !41
  %661 = insertelement <2 x float> poison, float %297, i64 0, !dbg !40
  %662 = insertelement <2 x float> %661, float %298, i64 1, !dbg !40
  %663 = insertelement <2 x float> poison, float %555, i64 0, !dbg !40
  %664 = insertelement <2 x float> %663, float %556, i64 1, !dbg !40
  %665 = fmul <2 x float> %662, %664, !dbg !40
  %666 = insertelement <2 x float> poison, float %587, i64 0, !dbg !39
  %667 = insertelement <2 x float> %666, float %588, i64 1, !dbg !39
  %668 = fmul <2 x float> %667, %665, !dbg !39
  %669 = fptrunc <2 x float> %668 to <2 x bfloat>, !dbg !41
  %670 = insertelement <2 x float> poison, float %299, i64 0, !dbg !40
  %671 = insertelement <2 x float> %670, float %300, i64 1, !dbg !40
  %672 = insertelement <2 x float> poison, float %557, i64 0, !dbg !40
  %673 = insertelement <2 x float> %672, float %558, i64 1, !dbg !40
  %674 = fmul <2 x float> %671, %673, !dbg !40
  %675 = insertelement <2 x float> poison, float %589, i64 0, !dbg !39
  %676 = insertelement <2 x float> %675, float %590, i64 1, !dbg !39
  %677 = fmul <2 x float> %676, %674, !dbg !39
  %678 = fptrunc <2 x float> %677 to <2 x bfloat>, !dbg !41
  %679 = insertelement <2 x float> poison, float %301, i64 0, !dbg !40
  %680 = insertelement <2 x float> %679, float %302, i64 1, !dbg !40
  %681 = insertelement <2 x float> poison, float %559, i64 0, !dbg !40
  %682 = insertelement <2 x float> %681, float %560, i64 1, !dbg !40
  %683 = fmul <2 x float> %680, %682, !dbg !40
  %684 = insertelement <2 x float> poison, float %591, i64 0, !dbg !39
  %685 = insertelement <2 x float> %684, float %592, i64 1, !dbg !39
  %686 = fmul <2 x float> %685, %683, !dbg !39
  %687 = fptrunc <2 x float> %686 to <2 x bfloat>, !dbg !41
  %688 = insertelement <2 x float> poison, float %303, i64 0, !dbg !40
  %689 = insertelement <2 x float> %688, float %304, i64 1, !dbg !40
  %690 = insertelement <2 x float> poison, float %561, i64 0, !dbg !40
  %691 = insertelement <2 x float> %690, float %562, i64 1, !dbg !40
  %692 = fmul <2 x float> %689, %691, !dbg !40
  %693 = insertelement <2 x float> poison, float %593, i64 0, !dbg !39
  %694 = insertelement <2 x float> %693, float %594, i64 1, !dbg !39
  %695 = fmul <2 x float> %694, %692, !dbg !39
  %696 = fptrunc <2 x float> %695 to <2 x bfloat>, !dbg !41
  %697 = insertelement <2 x float> poison, float %305, i64 0, !dbg !40
  %698 = insertelement <2 x float> %697, float %306, i64 1, !dbg !40
  %699 = insertelement <2 x float> poison, float %563, i64 0, !dbg !40
  %700 = insertelement <2 x float> %699, float %564, i64 1, !dbg !40
  %701 = fmul <2 x float> %698, %700, !dbg !40
  %702 = insertelement <2 x float> poison, float %595, i64 0, !dbg !39
  %703 = insertelement <2 x float> %702, float %596, i64 1, !dbg !39
  %704 = fmul <2 x float> %703, %701, !dbg !39
  %705 = fptrunc <2 x float> %704 to <2 x bfloat>, !dbg !41
  %706 = insertelement <2 x float> poison, float %307, i64 0, !dbg !40
  %707 = insertelement <2 x float> %706, float %308, i64 1, !dbg !40
  %708 = insertelement <2 x float> poison, float %565, i64 0, !dbg !40
  %709 = insertelement <2 x float> %708, float %566, i64 1, !dbg !40
  %710 = fmul <2 x float> %707, %709, !dbg !40
  %711 = insertelement <2 x float> poison, float %597, i64 0, !dbg !39
  %712 = insertelement <2 x float> %711, float %598, i64 1, !dbg !39
  %713 = fmul <2 x float> %712, %710, !dbg !39
  %714 = fptrunc <2 x float> %713 to <2 x bfloat>, !dbg !41
  %715 = insertelement <2 x float> poison, float %309, i64 0, !dbg !40
  %716 = insertelement <2 x float> %715, float %310, i64 1, !dbg !40
  %717 = insertelement <2 x float> poison, float %567, i64 0, !dbg !40
  %718 = insertelement <2 x float> %717, float %568, i64 1, !dbg !40
  %719 = fmul <2 x float> %716, %718, !dbg !40
  %720 = insertelement <2 x float> poison, float %599, i64 0, !dbg !39
  %721 = insertelement <2 x float> %720, float %600, i64 1, !dbg !39
  %722 = fmul <2 x float> %721, %719, !dbg !39
  %723 = fptrunc <2 x float> %722 to <2 x bfloat>, !dbg !41
  %724 = insertelement <2 x float> poison, float %311, i64 0, !dbg !40
  %725 = insertelement <2 x float> %724, float %312, i64 1, !dbg !40
  %726 = insertelement <2 x float> poison, float %569, i64 0, !dbg !40
  %727 = insertelement <2 x float> %726, float %570, i64 1, !dbg !40
  %728 = fmul <2 x float> %725, %727, !dbg !40
  %729 = insertelement <2 x float> poison, float %601, i64 0, !dbg !39
  %730 = insertelement <2 x float> %729, float %602, i64 1, !dbg !39
  %731 = fmul <2 x float> %730, %728, !dbg !39
  %732 = fptrunc <2 x float> %731 to <2 x bfloat>, !dbg !41
  %733 = insertelement <2 x float> poison, float %313, i64 0, !dbg !40
  %734 = insertelement <2 x float> %733, float %314, i64 1, !dbg !40
  %735 = insertelement <2 x float> poison, float %571, i64 0, !dbg !40
  %736 = insertelement <2 x float> %735, float %572, i64 1, !dbg !40
  %737 = fmul <2 x float> %734, %736, !dbg !40
  %738 = insertelement <2 x float> poison, float %603, i64 0, !dbg !39
  %739 = insertelement <2 x float> %738, float %604, i64 1, !dbg !39
  %740 = fmul <2 x float> %739, %737, !dbg !39
  %741 = fptrunc <2 x float> %740 to <2 x bfloat>, !dbg !41
  %742 = insertelement <2 x float> poison, float %315, i64 0, !dbg !40
  %743 = insertelement <2 x float> %742, float %316, i64 1, !dbg !40
  %744 = insertelement <2 x float> poison, float %573, i64 0, !dbg !40
  %745 = insertelement <2 x float> %744, float %574, i64 1, !dbg !40
  %746 = fmul <2 x float> %743, %745, !dbg !40
  %747 = insertelement <2 x float> poison, float %605, i64 0, !dbg !39
  %748 = insertelement <2 x float> %747, float %606, i64 1, !dbg !39
  %749 = fmul <2 x float> %748, %746, !dbg !39
  %750 = fptrunc <2 x float> %749 to <2 x bfloat>, !dbg !41
  %751 = shl nuw nsw i32 %19, 6, !dbg !42
  %752 = and i32 %751, 960, !dbg !42
  %753 = shl nuw nsw i32 %42, 5, !dbg !42
  %754 = shl nuw nsw i32 %19, 3, !dbg !42
  %755 = and i32 %754, 48, !dbg !42
  %756 = and i32 %19, 16, !dbg !42
  %757 = or disjoint i32 %752, %755, !dbg !42
  %758 = xor i32 %757, %756, !dbg !42
  %759 = or disjoint i32 %758, %753, !dbg !42
  %760 = getelementptr inbounds nuw i8, ptr addrspace(3) @global_smem, i32 %759, !dbg !42
  %761 = bitcast <2 x bfloat> %615 to i32, !dbg !42
  %762 = bitcast <2 x bfloat> %624 to i32, !dbg !42
  %763 = bitcast <2 x bfloat> %633 to i32, !dbg !42
  %764 = bitcast <2 x bfloat> %642 to i32, !dbg !42
  tail call void @llvm.nvvm.stmatrix.sync.aligned.m8n8.x4.b16.p3(ptr addrspace(3) %760, i32 %761, i32 %762, i32 %763, i32 %764), !dbg !42
  %765 = getelementptr inbounds nuw i8, ptr addrspace(3) %760, i32 4096, !dbg !42
  %766 = bitcast <2 x bfloat> %687 to i32, !dbg !42
  %767 = bitcast <2 x bfloat> %696 to i32, !dbg !42
  %768 = bitcast <2 x bfloat> %705 to i32, !dbg !42
  %769 = bitcast <2 x bfloat> %714 to i32, !dbg !42
  tail call void @llvm.nvvm.stmatrix.sync.aligned.m8n8.x4.b16.p3(ptr addrspace(3) nonnull %765, i32 %766, i32 %767, i32 %768, i32 %769), !dbg !42
  %770 = xor i32 %759, 32, !dbg !42
  %771 = getelementptr inbounds nuw i8, ptr addrspace(3) @global_smem, i32 %770, !dbg !42
  %772 = bitcast <2 x bfloat> %651 to i32, !dbg !42
  %773 = bitcast <2 x bfloat> %660 to i32, !dbg !42
  %774 = bitcast <2 x bfloat> %669 to i32, !dbg !42
  %775 = bitcast <2 x bfloat> %678 to i32, !dbg !42
  tail call void @llvm.nvvm.stmatrix.sync.aligned.m8n8.x4.b16.p3(ptr addrspace(3) %771, i32 %772, i32 %773, i32 %774, i32 %775), !dbg !42
  %776 = getelementptr inbounds nuw i8, ptr addrspace(3) %771, i32 4096, !dbg !42
  %777 = bitcast <2 x bfloat> %723 to i32, !dbg !42
  %778 = bitcast <2 x bfloat> %732 to i32, !dbg !42
  %779 = bitcast <2 x bfloat> %741 to i32, !dbg !42
  %780 = bitcast <2 x bfloat> %750 to i32, !dbg !42
  tail call void @llvm.nvvm.stmatrix.sync.aligned.m8n8.x4.b16.p3(ptr addrspace(3) nonnull %776, i32 %777, i32 %778, i32 %779, i32 %780), !dbg !42
  tail call void asm sideeffect "fence.proxy.async.shared::cta;", ""() #6, !dbg !42
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !42
  %781 = tail call { i32, i1 } @llvm.nvvm.elect.sync(i32 -1), !dbg !42
  %782 = extractvalue { i32, i1 } %781, 1, !dbg !42
  %783 = and i1 %21, %782, !dbg !42
  tail call void asm sideeffect "@$0 cp.async.bulk.tensor.2d.global.shared::cta.bulk_group [$1, {$2, $3}], [$4];", "b,l,r,r,r"(i1 %783, ptr %413, i32 %41, i32 %40, ptr addrspace(3) @global_smem) #6, !dbg !42
  tail call void @llvm.nvvm.cp.async.bulk.commit.group(), !dbg !42
  tail call void @llvm.nvvm.cp.async.bulk.wait.group.read(i32 0), !dbg !42
  tail call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0), !dbg !42
  ret void, !dbg !43
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 2147483647) i32 @llvm.nvvm.read.ptx.sreg.ctaid.x() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.y() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 65535) i32 @llvm.nvvm.read.ptx.sreg.ctaid.z() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 1, -2147483648) i32 @llvm.nvvm.read.ptx.sreg.nctaid.x() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 1, 65536) i32 @llvm.nvvm.read.ptx.sreg.nctaid.y() #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 1024) i32 @llvm.nvvm.read.ptx.sreg.tid.x() #1

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.bar.warp.sync(i32) #2

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier.cta.sync.aligned.all(i32) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #1

; Function Attrs: convergent mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite)
declare { i32, i1 } @llvm.nvvm.elect.sync(i32) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.ex2.approx.f(float) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(none)
declare float @llvm.nvvm.div.full(float, float) #4

; Function Attrs: nocallback nounwind memory(argmem: write)
declare void @llvm.nvvm.stmatrix.sync.aligned.m8n8.x4.b16.p3(ptr addrspace(3) writeonly captures(none), i32, i32, i32, i32) #5

; Function Attrs: nounwind
declare void @llvm.nvvm.cp.async.bulk.commit.group() #6

; Function Attrs: nounwind
declare void @llvm.nvvm.cp.async.bulk.wait.group.read(i32 immarg) #6

; Function Attrs: convergent nounwind
declare void @llvm.nvvm.wgmma.fence.sync.aligned() #7

; Function Attrs: convergent nounwind
declare void @llvm.nvvm.wgmma.commit_group.sync.aligned() #7

attributes #0 = { nounwind "nvvm.reqntid"="128" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { convergent nocallback nounwind }
attributes #3 = { convergent mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn memory(none) }
attributes #5 = { nocallback nounwind memory(argmem: write) }
attributes #6 = { nounwind }
attributes #7 = { convergent nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3}

!0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "triton", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly)
!1 = !DIFile(filename: "matmul_8192_8192_8192_bfloat16_dot.py", directory: "/home/muursep1/kernel-benchmarking/third_party/helion_kernels_lib/swiglu/ir_dumps/triton")
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 4, !"nvvm-reflect-ftz", i32 1}
!4 = distinct !DISubprogram(name: "_helion_swiglu_kernel_fn_dot", linkageName: "_helion_swiglu_kernel_fn_dot", scope: !1, file: !1, line: 19, type: !5, scopeLine: 19, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!5 = !DISubroutineType(cc: DW_CC_normal, types: !6)
!6 = !{}
!7 = !DILocation(line: 21, column: 67, scope: !4)
!8 = !DILocation(line: 23, column: 69, scope: !4)
!9 = !DILocation(line: 25, column: 71, scope: !4)
!10 = !DILocation(line: 32, column: 29, scope: !4)
!11 = !DILocation(line: 33, column: 35, scope: !4)
!12 = !DILocation(line: 33, column: 48, scope: !4)
!13 = !DILocation(line: 34, column: 41, scope: !4)
!14 = !DILocation(line: 35, column: 47, scope: !4)
!15 = !DILocation(line: 34, column: 60, scope: !4)
!16 = !DILocation(line: 34, column: 26, scope: !4)
!17 = !DILocation(line: 36, column: 23, scope: !4)
!18 = !DILocation(line: 37, column: 23, scope: !4)
!19 = !DILocation(line: 38, column: 41, scope: !4)
!20 = !DILocation(line: 38, column: 28, scope: !4)
!21 = !DILocation(line: 56, column: 52, scope: !4)
!22 = !DILocation(line: 47, column: 122, scope: !4)
!23 = !DILocation(line: 54, column: 29, scope: !4)
!24 = !DILocation(line: 60, column: 30, scope: !4)
!25 = !DILocation(line: 48, column: 31, scope: !4)
!26 = !DILocation(line: 56, column: 31, scope: !4)
!27 = !DILocation(line: 56, column: 84, scope: !4)
!28 = !DILocation(line: 57, column: 37, scope: !4)
!29 = !DILocation(line: 58, column: 56, scope: !4)
!30 = !DILocation(line: 62, column: 54, scope: !4)
!31 = !DILocation(line: 50, column: 30, scope: !32, inlinedAt: !34)
!32 = distinct !DILexicalBlockFile(scope: !4, file: !33, discriminator: 0)
!33 = !DIFile(filename: "standard.py", directory: "/usr/local/lib/python3.12/dist-packages/triton/language")
!34 = !DILocation(line: 65, column: 21, scope: !35)
!35 = distinct !DILexicalBlockFile(scope: !4, file: !1, discriminator: 0)
!36 = !DILocation(line: 50, column: 29, scope: !32, inlinedAt: !34)
!37 = !DILocation(line: 50, column: 20, scope: !32, inlinedAt: !34)
!38 = !DILocation(line: 50, column: 16, scope: !32, inlinedAt: !34)
!39 = !DILocation(line: 68, column: 16, scope: !4)
!40 = !DILocation(line: 66, column: 21, scope: !4)
!41 = !DILocation(line: 69, column: 23, scope: !4)
!42 = !DILocation(line: 70, column: 41, scope: !4)
!43 = !DILocation(line: 70, column: 4, scope: !4)

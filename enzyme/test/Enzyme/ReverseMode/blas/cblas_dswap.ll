;RUN: %opt < %s %loadEnzyme -enzyme -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx12.0.0"

@__const.main.m = private unnamed_addr constant [3 x double] [double 1.000000e+00, double 2.000000e+00, double 3.000000e+00], align 16
@__const.main.d_m = private unnamed_addr constant [3 x double] [double 2.000000e+00, double 4.000000e+00, double 6.000000e+00], align 16
@__const.main.n = private unnamed_addr constant [3 x double] [double 4.000000e+00, double 5.000000e+00, double 6.000000e+00], align 16
@__const.main.d_n = private unnamed_addr constant [3 x double] [double 8.000000e+00, double 1.000000e+01, double 1.200000e+01], align 16

; Function Attrs: nounwind ssp uwtable
define void @f(i32 %n, double* noalias %x, double* noalias %y) #0 {
entry:
  tail call void @cblas_dswap(i32 %n, double* %x, i32 1, double* %y, i32 1) #4
  ret void
}

declare void @cblas_dswap(i32, double*, i32, double*, i32) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
entry:
  %m = alloca [3 x double], align 16
  %d_m = alloca [3 x double], align 16
  %n = alloca [3 x double], align 16
  %d_n = alloca [3 x double], align 16
  %0 = bitcast [3 x double]* %m to i8*
  call void @llvm.lifetime.start.p0i8(i64 24, i8* nonnull %0) #4
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* noundef nonnull align 16 dereferenceable(24) %0, i8* noundef nonnull align 16 dereferenceable(24) bitcast ([3 x double]* @__const.main.m to i8*), i64 24, i1 false)
  %1 = bitcast [3 x double]* %d_m to i8*
  call void @llvm.lifetime.start.p0i8(i64 24, i8* nonnull %1) #4
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* noundef nonnull align 16 dereferenceable(24) %1, i8* noundef nonnull align 16 dereferenceable(24) bitcast ([3 x double]* @__const.main.d_m to i8*), i64 24, i1 false)
  %2 = bitcast [3 x double]* %n to i8*
  call void @llvm.lifetime.start.p0i8(i64 24, i8* nonnull %2) #4
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* noundef nonnull align 16 dereferenceable(24) %2, i8* noundef nonnull align 16 dereferenceable(24) bitcast ([3 x double]* @__const.main.n to i8*), i64 24, i1 false)
  %3 = bitcast [3 x double]* %d_n to i8*
  call void @llvm.lifetime.start.p0i8(i64 24, i8* nonnull %3) #4
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* noundef nonnull align 16 dereferenceable(24) %3, i8* noundef nonnull align 16 dereferenceable(24) bitcast ([3 x double]* @__const.main.d_n to i8*), i64 24, i1 false)
  %arraydecay = getelementptr inbounds [3 x double], [3 x double]* %m, i64 0, i64 0
  %arraydecay1 = getelementptr inbounds [3 x double], [3 x double]* %d_m, i64 0, i64 0
  %arraydecay2 = getelementptr inbounds [3 x double], [3 x double]* %n, i64 0, i64 0
  %arraydecay3 = getelementptr inbounds [3 x double], [3 x double]* %d_n, i64 0, i64 0
  call void @__enzyme_autodiff(i8* bitcast (void (i32, double*, double*)* @f to i8*), i32 3, double* nonnull %arraydecay, double* nonnull %arraydecay1, double* nonnull %arraydecay2, double* nonnull %arraydecay3) #4
  call void @llvm.lifetime.end.p0i8(i64 24, i8* nonnull %3) #4
  call void @llvm.lifetime.end.p0i8(i64 24, i8* nonnull %2) #4
  call void @llvm.lifetime.end.p0i8(i64 24, i8* nonnull %1) #4
  call void @llvm.lifetime.end.p0i8(i64 24, i8* nonnull %0) #4
  ret i32 0
}

; Function Attrs: argmemonly mustprogress nofree nosync nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #2

; Function Attrs: argmemonly mustprogress nofree nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #3

declare void @__enzyme_autodiff(i8*, i32, double*, double*, double*, double*) local_unnamed_addr #1

; Function Attrs: argmemonly mustprogress nofree nosync nounwind willreturn
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { argmemonly mustprogress nofree nosync nounwind willreturn }
attributes #3 = { argmemonly mustprogress nofree nounwind willreturn }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{!"Homebrew clang version 13.0.0"}

;CHECK:define internal void @diffef(i32 %n, double* noalias %x, double* %"x'", double* noalias %y, double* %"y'") #0 {
;CHECK-NEXT:entry:
;CHECK-NEXT:  tail call void @cblas_dswap(i32 %n, double* %x, i32 1, double* %y, i32 1) #4
;CHECK-NEXT:  call void @cblas_dswap(i32 %n, double* %"x'", i32 1, double* %"y'", i32 1)
;CHECK-NEXT:  ret void
;CHECK-NEXT:}

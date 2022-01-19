;RUN: %opt < %s %loadEnzyme -enzyme -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx12.0.0"

@__const.main.m = private unnamed_addr constant [3 x double] [double 1.000000e+00, double 2.000000e+00, double 3.000000e+00], align 16
@__const.main.d_m = private unnamed_addr constant [3 x double] [double 1.000000e+00, double 1.000000e+00, double 1.000000e+00], align 16

; Function Attrs: nounwind ssp uwtable
define void @f(double* noalias %x) #0 {
entry:
  tail call void @cblas_dscal(i32 3, double 2.000000e+00, double* %x, i32 1) #4
  ret void
}

declare void @cblas_dscal(i32, double, double*, i32) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
entry:
  %m = alloca [3 x double], align 16
  %d_m = alloca [3 x double], align 16
  %0 = bitcast [3 x double]* %m to i8*
  call void @llvm.lifetime.start.p0i8(i64 24, i8* nonnull %0) #4
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* noundef nonnull align 16 dereferenceable(24) %0, i8* noundef nonnull align 16 dereferenceable(24) bitcast ([3 x double]* @__const.main.m to i8*), i64 24, i1 false)
  %1 = bitcast [3 x double]* %d_m to i8*
  call void @llvm.lifetime.start.p0i8(i64 24, i8* nonnull %1) #4
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* noundef nonnull align 16 dereferenceable(24) %1, i8* noundef nonnull align 16 dereferenceable(24) bitcast ([3 x double]* @__const.main.d_m to i8*), i64 24, i1 false)
  %arraydecay = getelementptr inbounds [3 x double], [3 x double]* %m, i64 0, i64 0
  %arraydecay1 = getelementptr inbounds [3 x double], [3 x double]* %d_m, i64 0, i64 0
  call void @__enzyme_autodiff(i8* bitcast (void (double*)* @f to i8*), double* nonnull %arraydecay, double* nonnull %arraydecay1) #4
  call void @llvm.lifetime.end.p0i8(i64 24, i8* nonnull %1) #4
  call void @llvm.lifetime.end.p0i8(i64 24, i8* nonnull %0) #4
  ret i32 0
}

; Function Attrs: argmemonly mustprogress nofree nosync nounwind willreturn
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #2

; Function Attrs: argmemonly mustprogress nofree nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #3

declare void @__enzyme_autodiff(i8*, double*, double*) local_unnamed_addr #1

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

;CHECK:define internal void @diffef(double* noalias %x, double* %"x'") #0 {
;CHECK-NEXT:entry:
;CHECK-NEXT:  tail call void @cblas_dscal(i32 3, double 2.000000e+00, double* %x, i32 1) #4
;CHECK-NEXT:  call void @cblas_dscal(i32 3, double 2.000000e+00, double* %"x'", i32 1)
;CHECK-NEXT:  ret void
;CHECK-NEXT:}
 
;RUN: %opt < %s %loadEnzyme -enzyme -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__const.main.m = private unnamed_addr constant [3 x double] [double 1.000000e+00, double 2.000000e+00, double 3.000000e+00], align 16
@__const.main.d_m = private unnamed_addr constant [3 x double] [double 1.000000e+00, double 1.000000e+00, double 1.000000e+00], align 16
@.str = private unnamed_addr constant [10 x i8] c"%f %f %f\0A\00", align 1

; Function Attrs: noinline nounwind optnone ssp uwtable
define void @f(double* noalias %0) #0 {
  %2 = alloca double*, align 8
  store double* %0, double** %2, align 8
  %3 = load double*, double** %2, align 8
  call void @cblas_dscal(i32 3, double 2.000000e+00, double* %3, i32 1)
  ret void
}

declare void @cblas_dscal(i32, double, double*, i32) #1

; Function Attrs: noinline nounwind optnone ssp uwtable
define i32 @main() #0 {
  %1 = alloca [3 x double], align 16
  %2 = alloca [3 x double], align 16
  %3 = bitcast [3 x double]* %1 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 16 %3, i8* align 16 bitcast ([3 x double]* @__const.main.m to i8*), i64 24, i1 false)
  %4 = bitcast [3 x double]* %2 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 16 %4, i8* align 16 bitcast ([3 x double]* @__const.main.d_m to i8*), i64 24, i1 false)
  %5 = getelementptr inbounds [3 x double], [3 x double]* %1, i64 0, i64 0
  %6 = getelementptr inbounds [3 x double], [3 x double]* %2, i64 0, i64 0
  call void @__enzyme_autodiff(i8* bitcast (void (double*)* @f to i8*), double* %5, double* %6)
  %7 = getelementptr inbounds [3 x double], [3 x double]* %2, i64 0, i64 0
  %8 = load double, double* %7, align 16
  %9 = getelementptr inbounds [3 x double], [3 x double]* %2, i64 0, i64 1
  %10 = load double, double* %9, align 8
  %11 = getelementptr inbounds [3 x double], [3 x double]* %2, i64 0, i64 2
  %12 = load double, double* %11, align 16
  %13 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.str, i64 0, i64 0), double %8, double %10, double %12)
  ret i32 0
}

; Function Attrs: argmemonly nofree nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #2

declare void @__enzyme_autodiff(i8*, double*, double*) #1

declare i32 @printf(i8*, ...) #1

attributes #0 = { noinline nounwind optnone ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { argmemonly nofree nounwind willreturn }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{!"Homebrew clang version 13.0.0"}

;CHECK:define internal void @diffef(double* noalias %0, double* %"'") #3 {
;CHECK-NEXT:invert:
;CHECK-NEXT:  call void @cblas_dscal(i32 3, double 2.000000e+00, double* %0, i32 1)
;CHECK-NEXT:  call void @cblas_dscal(i32 3, double 2.000000e+00, double* %"'", i32 1)
;CHECK-NEXT:  ret void
;CHECK-NEXT:}

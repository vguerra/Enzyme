; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double, double)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x, double %y) {
entry:
  %0 = tail call fast double @llvm.pow.f64(double %x, double %y)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x, double %y) {
entry:
  %0 = tail call %struct.Gradients (double (double, double)*, ...) @__enzyme_fwdvectordiff(double (double, double)* nonnull @tester, double %x, [2 x double] [double 1.0, double 0.0], double %y, [2 x double] [double 0.0, double 1.0])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.pow.f64(double, double)

; Function Attrs: nounwind
declare double @__enzyme_fwddiff(double (double, double)*, ...)


; CHECK: define internal [2 x double] @fwdvectordiffetester(double %x, [2 x double] %"x'", double %y, [2 x double] %"y'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = fsub fast double %y, 1.000000e+00
; CHECK-NEXT:   %1 = call fast double @llvm.pow.f64(double %x, double %0)
; CHECK-NEXT:   %2 = fmul fast double %y, %1
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> {{poison|undef}}, double %2, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> {{poison|undef}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %3 = extractvalue [2 x double] %"x'", 0
; CHECK-NEXT:   %4 = insertelement <2 x double> undef, double %3, i64 0
; CHECK-NEXT:   %5 = extractvalue [2 x double] %"x'", 1
; CHECK-NEXT:   %6 = insertelement <2 x double> %4, double %5, i64 1
; CHECK-NEXT:   %7 = fmul fast <2 x double> %.splat, %6
; CHECK-NEXT:   %8 = call fast double @llvm.pow.f64(double %x, double %y)
; CHECK-NEXT:   %9 = call fast double @llvm.log.f64(double %x)
; CHECK-NEXT:   %10 = fmul fast double %8, %9
; CHECK-NEXT:   %.splatinsert1 = insertelement <2 x double> {{poison|undef}}, double %10, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <2 x double> %.splatinsert1, <2 x double> {{poison|undef}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %11 = extractvalue [2 x double] %"y'", 0
; CHECK-NEXT:   %12 = insertelement <2 x double> undef, double %11, i64 0
; CHECK-NEXT:   %13 = extractvalue [2 x double] %"y'", 1
; CHECK-NEXT:   %14 = insertelement <2 x double> %12, double %13, i64 1
; CHECK-NEXT:   %15 = fmul fast <2 x double> %.splat2, %14
; CHECK-NEXT:   %16 = fadd fast <2 x double> %7, %15
; CHECK-NEXT:   %17 = extractelement <2 x double> %16, i64 0
; CHECK-NEXT:   %18 = insertvalue [2 x double] undef, double %17, 0
; CHECK-NEXT:   %19 = extractelement <2 x double> %16, i64 1
; CHECK-NEXT:   %20 = insertvalue [2 x double] %18, double %19, 1
; CHECK-NEXT:   ret [2 x double] %20
; CHECK-NEXT: }
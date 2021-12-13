; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -early-cse -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double, double)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x, double %y) {
entry:
  %0 = fmul fast double %x, %y
  ret double %0
}

define %struct.Gradients @test_derivative(double %x, double %y) {
entry:
  %0 = tail call %struct.Gradients (double (double, double)*, ...) @__enzyme_fwdvectordiff(double (double, double)* nonnull @tester, double %x, [2 x double] [double 1.0, double 0.0], double %y, [2 x double] [double 0.0, double 1.0])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind
declare double @__enzyme_fwddiff(double (double, double)*, ...)


; CHECK: define internal [2 x double] @fwdvectordiffetester(double %x, [2 x double] %"x'", double %y, [2 x double] %"y'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [2 x double] %"x'", 0
; CHECK-NEXT:   %1 = insertelement <2 x double> undef, double %0, i64 0
; CHECK-NEXT:   %2 = extractvalue [2 x double] %"x'", 1
; CHECK-NEXT:   %3 = insertelement <2 x double> %1, double %2, i64 1
; CHECK-NEXT:   %4 = extractvalue [2 x double] %"y'", 0
; CHECK-NEXT:   %5 = insertelement <2 x double> undef, double %4, i64 0
; CHECK-NEXT:   %6 = extractvalue [2 x double] %"y'", 1
; CHECK-NEXT:   %7 = insertelement <2 x double> %5, double %6, i64 1
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> {{(poison|undef)}}, double %y, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> {{(poison|undef)}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %8 = fmul fast <2 x double> %3, %.splat
; CHECK-NEXT:   %.splatinsert1 = insertelement <2 x double> {{(poison|undef)}}, double %x, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <2 x double> %.splatinsert1, <2 x double> {{(poison|undef)}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %9 = fmul fast <2 x double> %7, %.splat2
; CHECK-NEXT:   %10 = fadd fast <2 x double> %8, %9
; CHECK-NEXT:   %11 = extractelement <2 x double> %10, i64 0
; CHECK-NEXT:   %12 = insertvalue [2 x double] undef, double %11, 0
; CHECK-NEXT:   %13 = extractelement <2 x double> %10, i64 1
; CHECK-NEXT:   %14 = insertvalue [2 x double] %12, double %13, 1
; CHECK-NEXT:   ret [2 x double] %14
; CHECK-NEXT: }
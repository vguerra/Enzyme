; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -early-cse -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double, double)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x, double %y) {
entry:
  %0 = tail call double @llvm.maxnum.f64(double %x, double %y)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x, double %y) {
entry:
  %0 = tail call %struct.Gradients (double (double, double)*, ...) @__enzyme_fwdvectordiff(double (double, double)* nonnull @tester, double %x, [2 x double] [double 1.0, double 0.0], double %y, [2 x double] [double 0.0, double 1.0])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.maxnum.f64(double, double)

; Function Attrs: nounwind
declare double @__enzyme_fwddiff(double (double, double)*, ...)


; CHECK: define internal [2 x double] @fwdvectordiffetester(double %x, [2 x double] %"x'", double %y, [2 x double] %"y'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = fcmp fast olt double %x, %y
; CHECK-NEXT:   %1 = extractvalue [2 x double] %"x'", 0
; CHECK-NEXT:   %2 = insertelement <2 x double> undef, double %1, i64 0
; CHECK-NEXT:   %3 = extractvalue [2 x double] %"x'", 1
; CHECK-NEXT:   %4 = insertelement <2 x double> %2, double %3, i64 1
; CHECK-NEXT:   %5 = extractvalue [2 x double] %"y'", 0
; CHECK-NEXT:   %6 = insertelement <2 x double> undef, double %5, i64 0
; CHECK-NEXT:   %7 = extractvalue [2 x double] %"y'", 1
; CHECK-NEXT:   %8 = insertelement <2 x double> %6, double %7, i64 1
; CHECK-NEXT:   %9 = select {{(fast )?}}i1 %0, <2 x double> %4, <2 x double> %8
; CHECK-NEXT:   %10 = extractelement <2 x double> %9, i64 0
; CHECK-NEXT:   %11 = insertvalue [2 x double] undef, double %10, 0
; CHECK-NEXT:   %12 = extractelement <2 x double> %9, i64 1
; CHECK-NEXT:   %13 = insertvalue [2 x double] %11, double %12, 1
; CHECK-NEXT:   ret [2 x double] %13
; CHECK-NEXT: }
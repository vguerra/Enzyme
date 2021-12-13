; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -early-cse -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; Function Attrs: nounwind readnone uwtable
define double @tester(double %x) {
entry:
  %0 = tail call fast double @llvm.fabs.f64(double %x)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [2 x double] [double 1.0, double 2.0])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.fabs.f64(double)


; CHECK: define internal [2 x double] @fwdvectordiffetester(double %x, [2 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [2 x double] %"x'", 0
; CHECK-NEXT:   %1 = insertelement <2 x double> undef, double %0, i64 0
; CHECK-NEXT:   %2 = extractvalue [2 x double] %"x'", 1
; CHECK-NEXT:   %3 = insertelement <2 x double> %1, double %2, i64 1
; CHECK-NEXT:   %4 = fcmp fast olt double %x, 0.000000e+00
; CHECK-NEXT:   %5 = select {{(fast )?}}i1 %4, double -1.000000e+00, double 1.000000e+00
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> {{poison|undef}}, double %5, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> {{poison|undef}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %6 = fmul fast <2 x double> %.splat, %3
; CHECK-NEXT:   %7 = extractelement <2 x double> %6, i64 0
; CHECK-NEXT:   %8 = insertvalue [2 x double] undef, double %7, 0
; CHECK-NEXT:   %9 = extractelement <2 x double> %6, i64 1
; CHECK-NEXT:   %10 = insertvalue [2 x double] %8, double %9, 1
; CHECK-NEXT:   ret [2 x double] %10
; CHECK-NEXT: }
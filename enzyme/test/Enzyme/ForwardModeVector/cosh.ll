; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; Function Attrs: nounwind readnone uwtable
define double @tester(double %x) {
entry:
  %0 = tail call fast double @cosh(double %x)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [2 x double] [double 0.000000e+00, double 1.000000e+00])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @cosh(double)


; CHECK: define internal [2 x double] @fwdvectordiffetester(double %x, [2 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = call fast double @sinh(double %x)
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> {{poison|undef}}, double %0, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> {{poison|undef}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %1 = extractvalue [2 x double] %"x'", 0
; CHECK-NEXT:   %2 = insertelement <2 x double> undef, double %1, i64 0
; CHECK-NEXT:   %3 = extractvalue [2 x double] %"x'", 1
; CHECK-NEXT:   %4 = insertelement <2 x double> %2, double %3, i64 1
; CHECK-NEXT:   %5 = fmul fast <2 x double> %4, %.splat
; CHECK-NEXT:   %6 = extractelement <2 x double> %5, i64 0
; CHECK-NEXT:   %7 = insertvalue [2 x double] undef, double %6, 0
; CHECK-NEXT:   %8 = extractelement <2 x double> %5, i64 1
; CHECK-NEXT:   %9 = insertvalue [2 x double] %7, double %8, 1
; CHECK-NEXT:   ret [2 x double] %9
; CHECK-NEXT: }
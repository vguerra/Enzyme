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

; CHECK: define internal <2 x double> @fwdvectordiffetester(double %x, <2 x double> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = call fast double @sinh(double %x)
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> poison, double %0, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> poison, <2 x i32> zeroinitializer
; CHECK-NEXT:   %1 = fmul fast <2 x double> %"x'", %.splat
; CHECK-NEXT:   ret <2 x double> %1
; CHECK-NEXT: }
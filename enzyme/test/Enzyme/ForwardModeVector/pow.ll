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


; CHECK: define internal {{(dso_local )?}}<2 x double> @fwdvectordiffetester(double %x, <2 x double> %"x'", double %y, <2 x double> %"y'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = fsub fast double %y, 1.000000e+00
; CHECK-NEXT:   %1 = call fast double @llvm.pow.f64(double %x, double %0)
; CHECK-NEXT:   %2 = fmul fast double %y, %1
; CHECK-NEXT:   %3 = call fast double @llvm.pow.f64(double %x, double %y)
; CHECK-NEXT:   %4 = call fast double @llvm.log.f64(double %x)
; CHECK-NEXT:   %5 = fmul fast double %3, %4
; CHECK-NEXT:   %6 = fadd fast double %2, %5
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> poison, double %6, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> poison, <2 x i32> zeroinitializer
; CHECK-NEXT:   ret <2 x double> %.splat
; CHECK-NEXT: }
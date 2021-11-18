; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -sroa -instsimplify -simplifycfg -adce -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

declare double @erfi(double)

define double @tester(double %x) {
entry:
  %call = call double @erfi(double %x)
  ret double %call
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [2 x double] [double 1.0, double 2.0])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind
declare double @__enzyme_fwddiff(double (double)*, ...)


; CHECK: define internal <2 x double> @fwdvectordiffetester(double %x, <2 x double> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = fmul fast double %x, %x
; CHECK-NEXT:   %1 = call fast double @llvm.exp.f64(double %0)
; CHECK-NEXT:   %2 = fmul fast double %1, 0x3FF20DD750429B6D
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> poison, double %2, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> poison, <2 x i32> zeroinitializer
; CHECK-NEXT:   %3 = fmul fast <2 x double> %.splat, %"x'"
; CHECK-NEXT:   ret <2 x double> %3
; CHECK-NEXT: }

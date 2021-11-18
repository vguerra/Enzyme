; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -early-cse -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

define double @square(double %x) {
entry:
  %mul = fmul fast double %x, %x
  ret double %mul
}

define %struct.Gradients @dsquare(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @square, double %x, [2 x double] [double 1.0, double 10.0])
  ret %struct.Gradients %0
}


; CHECK: define internal {{(dso_local )?}}<2 x double> @fwdvectordiffesquare(double %x, <2 x double> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> poison, double %x, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> poison, <2 x i32> zeroinitializer
; CHECK-NEXT:   %0 = fmul fast <2 x double> %"x'", %.splat
; CHECK-NEXT:   %1 = fadd fast <2 x double> %0, %0
; CHECK-NEXT:   ret <2 x double> %1
; CHECK-NEXT: }
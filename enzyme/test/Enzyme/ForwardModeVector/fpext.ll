; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -adce -instsimplify -S | FileCheck %s

%struct.Gradients = type { float, float }
%struct.ExtGradients = type { double, double }

; Function Attrs: nounwind
declare %struct.ExtGradients @__enzyme_fwdvectordiff(double (float)*, ...)

define double @tester(float %x) {
entry:
  %y = fpext float %x to double
  ret double %y
}

define %struct.ExtGradients @test_derivative(float %x) {
entry:
  %0 = tail call %struct.ExtGradients (double (float)*, ...) @__enzyme_fwdvectordiff(double (float)* nonnull @tester, float %x, [2 x float] [float 1.0, float 2.0])
  ret %struct.ExtGradients %0
}


; CHECK: define internal {{(dso_local )?}}<2 x double> @fwdvectordiffetester(float %x, <2 x float> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = fpext <2 x float> %"x'" to <2 x double>
; CHECK-NEXT:   ret <2 x double> %0
; CHECK-NEXT: }
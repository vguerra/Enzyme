; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x) {
entry:
  ret double 1.000000e+00
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [2 x double] [double 0.000000e+00, double 1.000000e+00])
  ret %struct.Gradients %0
}

; CHECK: define internal {{(dso_local )?}}<2 x double> @fwdvectordiffetester(double %x, <2 x double> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   ret <2 x double> zeroinitializer
; CHECK-NEXT: }
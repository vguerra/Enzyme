; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -adce -instsimplify -S | FileCheck %s

%struct.Gradients = type { double, double }

define double @tester(double %x) {
entry:
  %y = bitcast double %x to i64
  %z = bitcast i64 %y to double
  ret double %z
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %call = call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [2 x double] [double 1.000000e+00, double 0.000000e+00])
  ret %struct.Gradients %call
}

declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)


; CHECK: define internal [2 x double] @fwdvectordiffetester(double %x, [2 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   ret [2 x double] %"x'"
; CHECK-NEXT: }
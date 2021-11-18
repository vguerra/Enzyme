; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -adce -instsimplify -S | FileCheck %s

%struct.Gradients = type { float, float }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (float)*, ...)

define double @tester(float %x) {
entry:
  %y = fpext float %x to double
  ret double %y
}

define %struct.Gradients @test_derivative(float %x) {
entry:
  %0 = tail call %struct.Gradients (double (float)*, ...) @__enzyme_fwdvectordiff(double (float)* nonnull @tester, float %x, [2 x float] [float 1.0, float 2.0])
  ret %struct.Gradients %0
}
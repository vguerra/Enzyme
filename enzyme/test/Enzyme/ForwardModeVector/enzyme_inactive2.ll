; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x) {
entry:
  tail call void @myprint(double %x) #0
  ret double %x
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [2 x double] [double 1.0, double 2.0])
  ret %struct.Gradients %0
}

declare void @myprint(double %x)

attributes #0 = { "enzyme_inactive" }


; CHECK: define internal [2 x double] @fwdvectordiffetester(double %x, [2 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   tail call void @myprint(double %x) #0
; CHECK-NEXT:   ret [2 x double] %"x'"
; CHECK-NEXT: }
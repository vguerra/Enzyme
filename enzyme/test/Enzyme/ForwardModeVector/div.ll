; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -early-cse -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double,double)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x, double %y) {
entry:
  %0 = fdiv fast double %x, %y
  ret double %0
}

define %struct.Gradients @test_derivative(double %x, double %y) {
entry:
  %0 = tail call %struct.Gradients (double (double, double)*, ...) @__enzyme_fwdvectordiff(double (double, double)* nonnull @tester, double %x, [2 x double] [double 0.0, double 1.0], double %y, [2 x double] [double 1.0, double 0.0])
  ret %struct.Gradients %0
}

; CHECK: define internal {{(dso_local )?}}<2 x double> @fwdvectordiffetester(double %x, <2 x double> %"x'", double %y, <2 x double> %"y'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %.splatinsert = insertelement <2 x double> poison, double %y, i32 0
; CHECK-NEXT:   %.splat = shufflevector <2 x double> %.splatinsert, <2 x double> poison, <2 x i32> zeroinitializer
; CHECK-NEXT:   %0 = fmul fast <2 x double> %"x'", %.splat
; CHECK-NEXT:   %.splatinsert1 = insertelement <2 x double> poison, double %x, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <2 x double> %.splatinsert1, <2 x double> poison, <2 x i32> zeroinitializer
; CHECK-NEXT:   %1 = fmul fast <2 x double> %.splat2, %"y'"
; CHECK-NEXT:   %2 = fsub fast <2 x double> %0, %1
; CHECK-NEXT:   %3 = fmul fast <2 x double> %.splat, %.splat
; CHECK-NEXT:   %4 = fdiv fast <2 x double> %2, %3
; CHECK-NEXT:   ret <2 x double> %4
; CHECK-NEXT: }
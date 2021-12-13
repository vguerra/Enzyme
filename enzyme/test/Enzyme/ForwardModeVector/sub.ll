; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -instcombine -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double, double)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x, double %y) {
entry:
  %0 = fsub fast double %x, %y
  ret double %0
}

define %struct.Gradients @test_derivative(double %x, double %y) {
entry:
  %0 = tail call %struct.Gradients (double (double, double)*, ...) @__enzyme_fwdvectordiff(double (double, double)* nonnull @tester, double %x, [2 x double] [double 1.0, double 0.0], double %y, [2 x double] [double 0.0, double 1.0])
  ret %struct.Gradients %0
}


; CHECK: define internal [2 x double] @fwdvectordiffetester(double %x, [2 x double] %"x'", double %y, [2 x double] %"y'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [2 x double] %"x'", 0
; CHECK-NEXT:   %1 = insertelement <2 x double> undef, double %0, i64 0
; CHECK-NEXT:   %2 = extractvalue [2 x double] %"x'", 1
; CHECK-NEXT:   %3 = insertelement <2 x double> %1, double %2, i64 1
; CHECK-NEXT:   %4 = extractvalue [2 x double] %"y'", 0
; CHECK-NEXT:   %5 = insertelement <2 x double> undef, double %4, i64 0
; CHECK-NEXT:   %6 = extractvalue [2 x double] %"y'", 1
; CHECK-NEXT:   %7 = insertelement <2 x double> %5, double %6, i64 1
; CHECK-NEXT:   %8 = fsub fast <2 x double> %3, %7
; CHECK-NEXT:   %9 = extractelement <2 x double> %8, i64 0
; CHECK-NEXT:   %10 = insertvalue [2 x double] undef, double %9, 0
; CHECK-NEXT:   %11 = extractelement <2 x double> %8, i64 1
; CHECK-NEXT:   %12 = insertvalue [2 x double] %10, double %11, 1
; CHECK-NEXT:   ret [2 x double] %12
; CHECK-NEXT: }
; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -O3 -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -O3 -S | FileCheck %s

; Function Attrs: nounwind readnone uwtable
define double @tester(double %x) {
entry:
  %0 = tail call fast double @llvm.log2.f64(double %x)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [3 x double] [double 1.0, double 2.0, double 3.0])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.log2.f64(double)

; Function Attrs: nounwind
declare double @__enzyme_fwddiff(double (double)*, ...)


; CHECK: define %struct.Gradients @test_derivative(double %x)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %.scalar = fmul fast double %x, 0x3FE62E42FEFA39EF
; CHECK-NEXT:   %0 = insertelement <3 x double> poison, double %.scalar, i64 0
; CHECK-NEXT:   %1 = shufflevector <3 x double> %0, <3 x double> undef, <3 x i32> zeroinitializer
; CHECK-NEXT:   %2 = fdiv fast <3 x double> <double 1.000000e+00, double 2.000000e+00, double 3.000000e+00>, %1
; CHECK-NEXT:   %3 = extractelement <3 x double> %2, i64 0
; CHECK-NEXT:   %4 = insertvalue %struct.Gradients zeroinitializer, double %3, 0
; CHECK-NEXT:   %5 = extractelement <3 x double> %2, i64 1
; CHECK-NEXT:   %6 = insertvalue %struct.Gradients %4, double %5, 1
; CHECK-NEXT:   %7 = extractelement <3 x double> %2, i64 2
; CHECK-NEXT:   %8 = insertvalue %struct.Gradients %6, double %7, 2
; CHECK-NEXT:   ret %struct.Gradients %8
; CHECK-NEXT: }
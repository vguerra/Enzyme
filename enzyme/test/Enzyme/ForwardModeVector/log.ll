; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -O3 -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; Function Attrs: nounwind readnone uwtable
define double @tester(double %x) {
entry:
  %0 = tail call fast double @llvm.log.f64(double %x)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [3 x double] [double 1.0, double 2.0, double 3.0])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.log.f64(double)


; CHECK: define %struct.Gradients @test_derivative(double %x)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %.splatinsert.i = insertelement <3 x double> poison, double %x, i32 0
; CHECK-NEXT:   %.splat.i = shufflevector <3 x double> %.splatinsert.i, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %0 = fdiv fast <3 x double> <double 1.000000e+00, double 2.000000e+00, double 3.000000e+00>, %.splat.i
; CHECK-NEXT:   %1 = extractelement <3 x double> %0, i64 0
; CHECK-NEXT:   %2 = insertvalue %struct.Gradients zeroinitializer, double %1, 0
; CHECK-NEXT:   %3 = extractelement <3 x double> %0, i64 1
; CHECK-NEXT:   %4 = insertvalue %struct.Gradients %2, double %3, 1
; CHECK-NEXT:   %5 = extractelement <3 x double> %0, i64 2
; CHECK-NEXT:   %6 = insertvalue %struct.Gradients %4, double %5, 2
; CHECK-NEXT:   ret %struct.Gradients %6
; CHECK-NEXT: }
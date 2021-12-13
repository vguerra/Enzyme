; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -O3 -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind readnone uwtable
define double @tester(double %x) {
entry:
  %0 = tail call fast double @llvm.sqrt.f64(double %x)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, %struct.Gradients { double 1.0, double 2.0, double 3.0 })
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.sqrt.f64(double)

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)


; CHECK: define %struct.Gradients @test_derivative(double %x)
; CHECK-NEXT: entry
; CHECK-NEXT:   %0 = tail call fast double @llvm.sqrt.f64(double %x) #2
; CHECK-NEXT:   %.splatinsert.i = insertelement <3 x double> {{poison|undef}}, double %0, i32 0
; CHECK-NEXT:   %.splat.i = shufflevector <3 x double> %.splatinsert.i, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %1 = fdiv fast <3 x double> <double 5.000000e-01, double 1.000000e+00, double 1.500000e+00>, %.splat.i
; CHECK-NEXT:   %2 = fcmp fast oeq double %x, 0.000000e+00
; CHECK-NEXT:   %3 = select {{(fast )?}}i1 %2, <3 x double> zeroinitializer, <3 x double> %1
; CHECK-NEXT:   %4 = extractelement <3 x double> %3, i64 0
; CHECK-NEXT:   %5 = extractelement <3 x double> %3, i64 1
; CHECK-NEXT:   %6 = extractelement <3 x double> %3, i64 2
; CHECK-NEXT:   %7 = insertvalue %struct.Gradients zeroinitializer, double %4, 0
; CHECK-NEXT:   %8 = insertvalue %struct.Gradients %7, double %5, 1
; CHECK-NEXT:   %9 = insertvalue %struct.Gradients %8, double %6, 2
; CHECK-NEXT:   ret %struct.Gradients %9
; CHECK-NEXT: }
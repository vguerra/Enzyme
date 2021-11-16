; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -O3 -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; Function Attrs: nounwind readnone uwtable
define double @tester(double %x) {
entry:
  %0 = tail call fast double @llvm.cos.f64(double %x)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [2 x double] [double 0.000000e+00, double 1.000000e+00])
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.cos.f64(double)

; CHECK: define %struct.Gradients @test_derivative(double %x)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = tail call fast double @llvm.sin.f64(double %x) #2
; CHECK-NEXT:   %1 = {{(fsub fast double -0.000000e\+00,|fneg fast double)}} %0
; CHECK-NEXT:   %.splatinsert.i = insertelement <2 x double> poison, double %1, i32 0
; CHECK-NEXT:   %.splat.i = shufflevector <2 x double> %.splatinsert.i, <2 x double> poison, <2 x i32> zeroinitializer
; CHECK-NEXT:   %2 = fmul fast <2 x double> %.splat.i, <double 0.000000e+00, double 1.000000e+00>
; CHECK-NEXT:   %3 = extractelement <2 x double> %2, i64 0
; CHECK-NEXT:   %4 = insertvalue %struct.Gradients zeroinitializer, double %3, 0
; CHECK-NEXT:   %5 = extractelement <2 x double> %2, i64 1
; CHECK-NEXT:   %6 = insertvalue %struct.Gradients %4, double %5, 1
; CHECK-NEXT:   ret %struct.Gradients %6
; CHECK-NEXT: }
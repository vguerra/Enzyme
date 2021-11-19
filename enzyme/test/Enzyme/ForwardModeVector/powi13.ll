; RUN: if [ %llvmver -ge 13 ]; then %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s; fi

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double, i32)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x, i32 %y) {
entry:
  %0 = tail call fast double @llvm.powi.f64.i32(double %x, i32 %y)
  ret double %0
}

define %struct.Gradients @test_derivative(double %x, i32 %y) {
entry:
  %0 = tail call %struct.Gradients (double (double, i32)*, ...) @__enzyme_fwdvectordiff(double (double, i32)* nonnull @tester, double %x, [3 x double] [double 1.0, double 2.0, double 3.0], i32 %y)
  ret %struct.Gradients %0
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.powi.f64.i32(double, i32)


; CHECK: define internal {{(dso_local )?}}<3 x double> @fwdvectordiffetester(double %x, <3 x double> %"x'", i32 %y)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = sub i32 %y, 1
; CHECK-NEXT:   %1 = call fast double @llvm.powi.f64(double %x, i32 %0)
; CHECK-NEXT:   %2 = sitofp i32 %y to double
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> poison, double %1, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %.splatinsert1 = insertelement <3 x double> poison, double %2, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <3 x double> %.splatinsert1, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %3 = fmul fast <3 x double> %"x'", %.splat
; CHECK-NEXT:   %4 = fmul fast <3 x double> %3, %.splat2
; CHECK-NEXT:   ret <3 x double> %4
; CHECK-NEXT: }

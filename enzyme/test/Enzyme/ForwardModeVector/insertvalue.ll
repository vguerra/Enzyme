; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; Function Attrs: noinline nounwind readnone uwtable
define double @tester(double %x) {
entry:
  %agg1 = insertvalue [3 x double] undef, double %x, 0
  %mul = fmul double %x, %x
  %agg2 = insertvalue [3 x double] %agg1, double %mul, 1
  %add = fadd double %mul, 2.0
  %agg3 = insertvalue [3 x double] %agg2, double %add, 2
  %res = extractvalue [3 x double] %agg2, 1
  ret double %res
}

define %struct.Gradients @test_derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @tester, double %x, [3 x double] [double 1.0, double 2.0, double 3.0])
  ret %struct.Gradients %0
}


; CHECK: define internal [3 x double] @fwdvectordiffetester(double %x, [3 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [3 x double] %"x'", 0
; CHECK-NEXT:   %1 = insertelement <3 x double> undef, double %0, i64 0
; CHECK-NEXT:   %2 = extractvalue [3 x double] %"x'", 1
; CHECK-NEXT:   %3 = insertelement <3 x double> %1, double %2, i64 1
; CHECK-NEXT:   %4 = extractvalue [3 x double] %"x'", 2
; CHECK-NEXT:   %5 = insertelement <3 x double> %3, double %4, i64 2
; CHECK-NEXT:   %6 = extractvalue [3 x double] %"x'", 0
; CHECK-NEXT:   %7 = insertelement <3 x double> undef, double %6, i64 0
; CHECK-NEXT:   %8 = extractvalue [3 x double] %"x'", 1
; CHECK-NEXT:   %9 = insertelement <3 x double> %7, double %8, i64 1
; CHECK-NEXT:   %10 = extractvalue [3 x double] %"x'", 2
; CHECK-NEXT:   %11 = insertelement <3 x double> %9, double %10, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{poison|undef}}, double %x, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %12 = fmul fast <3 x double> %5, %.splat
; CHECK-NEXT:   %.splatinsert1 = insertelement <3 x double> {{poison|undef}}, double %x, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <3 x double> %.splatinsert1, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %13 = fmul fast <3 x double> %11, %.splat2
; CHECK-NEXT:   %14 = fadd fast <3 x double> %12, %13
; CHECK-NEXT:   %15 = extractelement <3 x double> %14, i64 0
; CHECK-NEXT:   %16 = extractelement <3 x double> %14, i64 1
; CHECK-NEXT:   %17 = extractelement <3 x double> %14, i64 2
; CHECK-NEXT:   %18 = insertvalue [3 x double] undef, double %15, 0
; CHECK-NEXT:   %19 = insertvalue [3 x double] %18, double %16, 1
; CHECK-NEXT:   %20 = insertvalue [3 x double] %19, double %17, 2
; CHECK-NEXT:   ret [3 x double] %20
; CHECK-NEXT: }
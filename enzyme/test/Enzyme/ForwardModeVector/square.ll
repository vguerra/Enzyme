; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -early-cse -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

define double @square(double %x) {
entry:
  %mul = fmul fast double %x, %x
  ret double %mul
}

define %struct.Gradients @dsquare(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @square, double %x, [3 x double] [double 1.0, double 10.0, double 100.0])
  ret %struct.Gradients %0
}


; CHECK: define internal [3 x double] @fwdvectordiffesquare(double %x, [3 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [3 x double] %"x'", 0
; CHECK-NEXT:   %1 = insertelement <3 x double> undef, double %0, i64 0
; CHECK-NEXT:   %2 = extractvalue [3 x double] %"x'", 1
; CHECK-NEXT:   %3 = insertelement <3 x double> %1, double %2, i64 1
; CHECK-NEXT:   %4 = extractvalue [3 x double] %"x'", 2
; CHECK-NEXT:   %5 = insertelement <3 x double> %3, double %4, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{(poison|undef)}}, double %x, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{(poison|undef)}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %6 = fmul fast <3 x double> %5, %.splat
; CHECK-NEXT:   %7 = fadd fast <3 x double> %6, %6
; CHECK-NEXT:   %8 = extractelement <3 x double> %7, i64 0
; CHECK-NEXT:   %9 = insertvalue [3 x double] undef, double %8, 0
; CHECK-NEXT:   %10 = extractelement <3 x double> %7, i64 1
; CHECK-NEXT:   %11 = insertvalue [3 x double] %9, double %10, 1
; CHECK-NEXT:   %12 = extractelement <3 x double> %7, i64 2
; CHECK-NEXT:   %13 = insertvalue [3 x double] %11, double %12, 2
; CHECK-NEXT:   ret [3 x double] %13
; CHECK-NEXT: }
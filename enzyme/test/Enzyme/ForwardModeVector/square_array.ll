; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -early-cse -S | FileCheck %s

%struct.GradientsIn = type { double, double, double }
%struct.GradientsOut = type { { double, double }, { double, double }, { double, double } }

define { double, double } @squared(double %x) {
entry:
  %mul = fmul double %x, %x
  %mul2 = fmul double %mul, %x
  %.fca.0.insert = insertvalue { double, double } undef, double %mul, 0
  %.fca.1.insert = insertvalue { double, double } %.fca.0.insert, double %mul2, 1
  ret { double, double } %.fca.1.insert
}

define %struct.GradientsOut @dsquared(double %x) {
entry:
  %call = call %struct.GradientsOut (i8*, ...) @__enzyme_fwdvectordiff(i8* bitcast ({ double, double } (double)* @squared to i8*), double %x, %struct.GradientsIn { double 1.0, double 2.0, double 3.0 })
  ret %struct.GradientsOut %call
}

declare %struct.GradientsOut @__enzyme_fwdvectordiff(i8*, ...)


; CHECK: define internal [3 x { double, double }] @fwdvectordiffesquared(double %x, [3 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %mul = fmul double %x, %x
; CHECK-NEXT:   %0 = extractvalue [3 x double] %"x'", 0
; CHECK-NEXT:   %1 = insertelement <3 x double> undef, double %0, i64 0
; CHECK-NEXT:   %2 = extractvalue [3 x double] %"x'", 1
; CHECK-NEXT:   %3 = insertelement <3 x double> %1, double %2, i64 1
; CHECK-NEXT:   %4 = extractvalue [3 x double] %"x'", 2
; CHECK-NEXT:   %5 = insertelement <3 x double> %3, double %4, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{poison|undef}}, double %x, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %6 = fmul fast <3 x double> %5, %.splat
; CHECK-NEXT:   %7 = fadd fast <3 x double> %6, %6
; CHECK-NEXT:   %8 = extractelement <3 x double> %7, i64 0
; CHECK-NEXT:   %9 = insertvalue [3 x double] undef, double %8, 0
; CHECK-NEXT:   %10 = extractelement <3 x double> %7, i64 1
; CHECK-NEXT:   %11 = insertvalue [3 x double] %9, double %10, 1
; CHECK-NEXT:   %12 = extractelement <3 x double> %7, i64 2
; CHECK-NEXT:   %13 = insertvalue [3 x double] %11, double %12, 2
; CHECK-NEXT:   %14 = insertelement <3 x double> undef, double %8, i64 0
; CHECK-NEXT:   %15 = insertelement <3 x double> %14, double %10, i64 1
; CHECK-NEXT:   %16 = insertelement <3 x double> %15, double %12, i64 2
; CHECK-NEXT:   %17 = fmul fast <3 x double> %16, %.splat
; CHECK-NEXT:   %.splatinsert5 = insertelement <3 x double> {{poison|undef}}, double %mul, i32 0
; CHECK-NEXT:   %.splat6 = shufflevector <3 x double> %.splatinsert5, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %18 = fmul fast <3 x double> %5, %.splat6
; CHECK-NEXT:   %19 = fadd fast <3 x double> %17, %18
; CHECK-NEXT:   %20 = extractelement <3 x double> %19, i64 0
; CHECK-NEXT:   %21 = insertvalue [3 x double] undef, double %20, 0
; CHECK-NEXT:   %22 = extractelement <3 x double> %19, i64 1
; CHECK-NEXT:   %23 = insertvalue [3 x double] %21, double %22, 1
; CHECK-NEXT:   %24 = extractelement <3 x double> %19, i64 2
; CHECK-NEXT:   %25 = insertvalue [3 x double] %23, double %24, 2
; CHECK-NEXT:   %26 = insertvalue { double, double } zeroinitializer, double %8, 0
; CHECK-NEXT:   %27 = insertvalue [3 x { double, double }] undef, { double, double } %26, 0
; CHECK-NEXT:   %28 = insertvalue { double, double } zeroinitializer, double %10, 0
; CHECK-NEXT:   %29 = insertvalue [3 x { double, double }] %27, { double, double } %28, 1
; CHECK-NEXT:   %30 = insertvalue { double, double } zeroinitializer, double %12, 0
; CHECK-NEXT:   %31 = insertvalue [3 x { double, double }] %29, { double, double } %30, 2
; CHECK-NEXT:   %32 = insertvalue { double, double } %26, double %20, 1
; CHECK-NEXT:   %33 = insertvalue [3 x { double, double }] undef, { double, double } %32, 0
; CHECK-NEXT:   %34 = insertvalue { double, double } %28, double %22, 1
; CHECK-NEXT:   %35 = insertvalue [3 x { double, double }] %33, { double, double } %34, 1
; CHECK-NEXT:   %36 = insertvalue { double, double } %30, double %24, 1
; CHECK-NEXT:   %37 = insertvalue [3 x { double, double }] %35, { double, double } %36, 2
; CHECK-NEXT:   ret [3 x { double, double }] %37
; CHECK-NEXT: }
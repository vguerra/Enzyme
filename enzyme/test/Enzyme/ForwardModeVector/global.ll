; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double, double }

@global = external dso_local local_unnamed_addr global double, align 8, !enzyme_shadow !{[3 x double*] [double* @dglobal1, double* @dglobal2, double* @dglobal3]}
@dglobal1 = external dso_local local_unnamed_addr global double, align 8
@dglobal2 = external dso_local local_unnamed_addr global double, align 8
@dglobal3 = external dso_local local_unnamed_addr global double, align 8

declare dso_local %struct.Gradients @_Z22__enzyme_fwdvectordiffPFddEz(double (double)*, ...)

define dso_local double @_Z9mulglobald(double %x) {
entry:
  %0 = load double, double* @global, align 8
  %mul = fmul double %0, %x
  ret double %mul
}

define dso_local void @_Z10derivatived(double %x) {
entry:
  call %struct.Gradients (double (double)*, ...) @_Z22__enzyme_fwdvectordiffPFddEz(double (double)* nonnull @_Z9mulglobald, double %x, [3 x double] [double 1.0 , double 2.0, double 3.0])
  ret void
}


; CHECK: define internal [3 x double] @fwdvectordiffe_Z9mulglobald(double %x, [3 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = load double, double* @global, align 8
; CHECK-NEXT:   %1 = load double, double* @dglobal1, align 8
; CHECK-NEXT:   %2 = load double, double* @dglobal2, align 8
; CHECK-NEXT:   %3 = load double, double* @dglobal3, align 8
; CHECK-NEXT:   %4 = insertelement <3 x double> undef, double %1, i64 0
; CHECK-NEXT:   %5 = insertelement <3 x double> %4, double %2, i64 1
; CHECK-NEXT:   %6 = insertelement <3 x double> %5, double %3, i64 2
; CHECK-NEXT:   %7 = extractvalue [3 x double] %"x'", 0
; CHECK-NEXT:   %8 = insertelement <3 x double> undef, double %7, i64 0
; CHECK-NEXT:   %9 = extractvalue [3 x double] %"x'", 1
; CHECK-NEXT:   %10 = insertelement <3 x double> %8, double %9, i64 1
; CHECK-NEXT:   %11 = extractvalue [3 x double] %"x'", 2
; CHECK-NEXT:   %12 = insertelement <3 x double> %10, double %11, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{poison|undef}}, double %x, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %13 = fmul fast <3 x double> %6, %.splat
; CHECK-NEXT:   %.splatinsert1 = insertelement <3 x double> {{poison|undef}}, double %0, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <3 x double> %.splatinsert1, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %14 = fmul fast <3 x double> %12, %.splat2
; CHECK-NEXT:   %15 = fadd fast <3 x double> %13, %14
; CHECK-NEXT:   %16 = extractelement <3 x double> %15, i64 0
; CHECK-NEXT:   %17 = insertvalue [3 x double] undef, double %16, 0
; CHECK-NEXT:   %18 = extractelement <3 x double> %15, i64 1
; CHECK-NEXT:   %19 = insertvalue [3 x double] %17, double %18, 1
; CHECK-NEXT:   %20 = extractelement <3 x double> %15, i64 2
; CHECK-NEXT:   %21 = insertvalue [3 x double] %19, double %20, 2
; CHECK-NEXT:   ret [3 x double] %21
; CHECK-NEXT: }
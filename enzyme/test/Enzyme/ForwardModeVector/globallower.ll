; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-lower-globals -mem2reg -sroa -simplifycfg -instsimplify -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

@global = external dso_local local_unnamed_addr global double, align 8

; Function Attrs: noinline norecurse nounwind readonly uwtable
define double @mulglobal(double %x) {
entry:
  %l1 = load double, double* @global, align 8
  %mul = fmul fast double %l1, %x
  store double %mul, double* @global, align 8
  %l2 = load double, double* @global, align 8
  %mul2 = fmul fast double %l2, %l2
  store double %mul2, double* @global, align 8
  %l3 = load double, double* @global, align 8
  ret double %l3
}

; Function Attrs: noinline nounwind uwtable
define %struct.Gradients @derivative(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @mulglobal, double %x, %struct.Gradients {double 1.0, double 2.0, double 3.0})
  ret %struct.Gradients %0
}


; CHECK: define internal [3 x double] @fwdvectordiffemulglobal(double %x, [3 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %"global'ipa" = alloca double, align 8
; CHECK-NEXT:   %"global'ipa7" = alloca double, align 8
; CHECK-NEXT:   %"global'ipa8" = alloca double, align 8
; CHECK-NEXT:   %0 = bitcast double* %"global'ipa" to i8*
; CHECK-NEXT:   call void @llvm.memset.p0i8.i64(i8* nonnull align 8 %0, i8 0, i64 8, i1 false)
; CHECK-NEXT:   %1 = bitcast double* %"global'ipa7" to i8*
; CHECK-NEXT:   call void @llvm.memset.p0i8.i64(i8* nonnull align 8 %1, i8 0, i64 8, i1 false)
; CHECK-NEXT:   %2 = bitcast double* %"global'ipa8" to i8*
; CHECK-NEXT:   call void @llvm.memset.p0i8.i64(i8* nonnull align 8 %2, i8 0, i64 8, i1 false)
; CHECK-NEXT:   %global_local.0.copyload = load double, double* @global, align 8
; CHECK-NEXT:   %mul = fmul fast double %global_local.0.copyload, %x
; CHECK-NEXT:   %3 = extractvalue [3 x double] %"x'", 0
; CHECK-NEXT:   %4 = insertelement <3 x double> undef, double %3, i64 0
; CHECK-NEXT:   %5 = extractvalue [3 x double] %"x'", 1
; CHECK-NEXT:   %6 = insertelement <3 x double> %4, double %5, i64 1
; CHECK-NEXT:   %7 = extractvalue [3 x double] %"x'", 2
; CHECK-NEXT:   %8 = insertelement <3 x double> %6, double %7, i64 2
; CHECK-NEXT:   %.splatinsert1 = insertelement <3 x double> {{poison|undef}}, double %global_local.0.copyload, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <3 x double> %.splatinsert1, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %9 = fmul fast <3 x double> %8, %.splat2
; CHECK-NEXT:   %10 = extractelement <3 x double> %9, i64 0
; CHECK-NEXT:   %11 = extractelement <3 x double> %9, i64 1
; CHECK-NEXT:   %12 = extractelement <3 x double> %9, i64 2
; CHECK-NEXT:   %mul2 = fmul fast double %mul, %mul
; CHECK-NEXT:   %13 = insertelement <3 x double> undef, double %10, i64 0
; CHECK-NEXT:   %14 = insertelement <3 x double> %13, double %11, i64 1
; CHECK-NEXT:   %15 = insertelement <3 x double> %14, double %12, i64 2
; CHECK-NEXT:   %16 = insertelement <3 x double> undef, double %10, i64 0
; CHECK-NEXT:   %17 = insertelement <3 x double> %16, double %11, i64 1
; CHECK-NEXT:   %18 = insertelement <3 x double> %17, double %12, i64 2
; CHECK-NEXT:   %.splatinsert3 = insertelement <3 x double> {{poison|undef}}, double %mul, i32 0
; CHECK-NEXT:   %.splat4 = shufflevector <3 x double> %.splatinsert3, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %19 = fmul fast <3 x double> %15, %.splat4
; CHECK-NEXT:   %.splatinsert5 = insertelement <3 x double> {{poison|undef}}, double %mul, i32 0
; CHECK-NEXT:   %.splat6 = shufflevector <3 x double> %.splatinsert5, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %20 = fmul fast <3 x double> %18, %.splat6
; CHECK-NEXT:   %21 = fadd fast <3 x double> %19, %20
; CHECK-NEXT:   %22 = extractelement <3 x double> %21, i64 0
; CHECK-NEXT:   %23 = insertvalue [3 x double] undef, double %22, 0
; CHECK-NEXT:   %24 = extractelement <3 x double> %21, i64 1
; CHECK-NEXT:   %25 = insertvalue [3 x double] %23, double %24, 1
; CHECK-NEXT:   %26 = extractelement <3 x double> %21, i64 2
; CHECK-NEXT:   %27 = insertvalue [3 x double] %25, double %26, 2
; CHECK-NEXT:   store double %mul2, double* @global, align 8
; CHECK-NEXT:   store double %22, double* %"global'ipa", align 8
; CHECK-NEXT:   store double %24, double* %"global'ipa7", align 8
; CHECK-NEXT:   store double %26, double* %"global'ipa8", align 8
; CHECK-NEXT:   ret [3 x double] %27
; CHECK-NEXT: }

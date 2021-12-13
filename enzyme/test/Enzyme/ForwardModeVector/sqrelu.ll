; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -inline -mem2reg -simplifycfg -adce -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)

; Function Attrs: nounwind readnone uwtable
define dso_local double @sqrelu(double %x) #0 {
entry:
  %cmp = fcmp fast ogt double %x, 0.000000e+00
  br i1 %cmp, label %cond.true, label %cond.end

cond.true:                                        ; preds = %entry
  %0 = tail call fast double @llvm.sin.f64(double %x)
  %mul = fmul fast double %0, %x
  %1 = tail call fast double @llvm.sqrt.f64(double %mul)
  br label %cond.end

cond.end:                                         ; preds = %entry, %cond.true
  %cond = phi double [ %1, %cond.true ], [ 0.000000e+00, %entry ]
  ret double %cond
}

; Function Attrs: nounwind readnone speculatable
declare double @llvm.sin.f64(double) #1

; Function Attrs: nounwind readnone speculatable
declare double @llvm.sqrt.f64(double) #1

; Function Attrs: nounwind uwtable
define dso_local %struct.Gradients @dsqrelu(double %x) local_unnamed_addr #2 {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @sqrelu, double %x, [2 x double] [double 1.0, double 1.5])
  ret %struct.Gradients %0
}

attributes #0 = { nounwind readnone uwtable }
attributes #1 = { nounwind readnone speculatable }
attributes #2 = { nounwind uwtable }
attributes #3 = { nounwind }


; CHECK: define dso_local %struct.Gradients @dsqrelu(double %x)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %cmp.i = fcmp fast ogt double %x, 0.000000e+00
; CHECK-NEXT:   br i1 %cmp.i, label %cond.true.i, label %fwdvectordiffesqrelu.exit

; CHECK: cond.true.i:                                      ; preds = %entry
; CHECK-NEXT:   %0 = call fast double @llvm.sin.f64(double %x) #3
; CHECK-NEXT:   %1 = call fast double @llvm.cos.f64(double %x) #3
; CHECK-NEXT:   %.splatinsert.i = insertelement <2 x double> {{poison|undef}}, double %1, i32 0
; CHECK-NEXT:   %.splat.i = shufflevector <2 x double> %.splatinsert.i, <2 x double> {{poison|undef}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %2 = fmul fast <2 x double> <double 1.000000e+00, double 1.500000e+00>, %.splat.i
; CHECK-NEXT:   %3 = extractelement <2 x double> %2, i64 0
; CHECK-NEXT:   %4 = extractelement <2 x double> %2, i64 1
; CHECK-NEXT:   %mul.i = fmul fast double %0, %x
; CHECK-NEXT:   %5 = insertelement <2 x double> undef, double %3, i64 0
; CHECK-NEXT:   %6 = insertelement <2 x double> %5, double %4, i64 1
; CHECK-NEXT:   %.splatinsert1.i = insertelement <2 x double> {{poison|undef}}, double %x, i32 0
; CHECK-NEXT:   %.splat2.i = shufflevector <2 x double> %.splatinsert1.i, <2 x double> {{poison|undef}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %7 = fmul fast <2 x double> %6, %.splat2.i
; CHECK-NEXT:   %.splatinsert3.i = insertelement <2 x double> {{poison|undef}}, double %0, i32 0
; CHECK-NEXT:   %.splat4.i = shufflevector <2 x double> %.splatinsert3.i, <2 x double> {{poison|undef}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %8 = fmul fast <2 x double> <double 1.000000e+00, double 1.500000e+00>, %.splat4.i
; CHECK-NEXT:   %9 = fadd fast <2 x double> %7, %8
; CHECK-NEXT:   %10 = extractelement <2 x double> %9, i64 0
; CHECK-NEXT:   %11 = extractelement <2 x double> %9, i64 1
; CHECK-NEXT:   %12 = insertelement <2 x double> undef, double %10, i64 0
; CHECK-NEXT:   %13 = insertelement <2 x double> %12, double %11, i64 1
; CHECK-NEXT:   %14 = call fast double @llvm.sqrt.f64(double %mul.i) #3
; CHECK-NEXT:   %.splatinsert5.i = insertelement <2 x double> {{poison|undef}}, double %14, i32 0
; CHECK-NEXT:   %.splat6.i = shufflevector <2 x double> %.splatinsert5.i, <2 x double> {{poison|undef}}, <2 x i32> zeroinitializer
; CHECK-NEXT:   %15 = fmul fast <2 x double> <double 5.000000e-01, double 5.000000e-01>, %13
; CHECK-NEXT:   %16 = fdiv fast <2 x double> %15, %.splat6.i
; CHECK-NEXT:   %17 = fcmp fast oeq double %mul.i, 0.000000e+00
; CHECK-NEXT:   %18 = select {{(fast )?}}i1 %17, <2 x double> zeroinitializer, <2 x double> %16
; CHECK-NEXT:   %19 = extractelement <2 x double> %18, i64 0
; CHECK-NEXT:   %20 = insertvalue [2 x double] undef, double %19, 0
; CHECK-NEXT:   %21 = extractelement <2 x double> %18, i64 1
; CHECK-NEXT:   %22 = insertvalue [2 x double] %20, double %21, 1
; CHECK-NEXT:   br label %fwdvectordiffesqrelu.exit

; CHECK: fwdvectordiffesqrelu.exit:                        ; preds = %entry, %cond.true.i
; CHECK-NEXT:   %"cond'.i" = phi {{(fast )?}}[2 x double] [ %22, %cond.true.i ], [ zeroinitializer, %entry ]
; CHECK-NEXT:   %23 = extractvalue [2 x double] %"cond'.i", 0
; CHECK-NEXT:   %24 = insertvalue %struct.Gradients zeroinitializer, double %23, 0
; CHECK-NEXT:   %25 = extractvalue [2 x double] %"cond'.i", 1
; CHECK-NEXT:   %26 = insertvalue %struct.Gradients %24, double %25, 1
; CHECK-NEXT:   ret %struct.Gradients %26
; CHECK-NEXT: }
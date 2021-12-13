; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -adce -correlated-propagation -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double*, double*, double* }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, double*, %struct.Gradients)

; Function Attrs: noinline norecurse nounwind uwtable
define dso_local zeroext i1 @metasubf(double* nocapture %x) local_unnamed_addr #0 {
entry:
  %arrayidx = getelementptr inbounds double, double* %x, i64 1
  store double 3.000000e+00, double* %arrayidx, align 8
  %0 = load double, double* %x, align 8
  %cmp = fcmp fast oeq double %0, 2.000000e+00
  ret i1 %cmp
}

; Function Attrs: noinline norecurse nounwind uwtable
define dso_local zeroext i1 @subf(double* nocapture %x) local_unnamed_addr #0 {
entry:
  %0 = load double, double* %x, align 8
  %mul = fmul fast double %0, %0
  store double %mul, double* %x, align 8
  %call = tail call zeroext i1 @metasubf(double* %x)
  ret i1 %call
}

; Function Attrs: noinline norecurse nounwind uwtable
define dso_local void @f(double* nocapture %x) #0 {
entry:
  %call = tail call zeroext i1 @subf(double* %x)
  store double 2.000000e+00, double* %x, align 8
  ret void
}

; Function Attrs: noinline nounwind uwtable
define dso_local %struct.Gradients @dsumsquare(double* %x, %struct.Gradients %xp) local_unnamed_addr #1 {
entry:
  %call = tail call %struct.Gradients @__enzyme_fwdvectordiff(i8* bitcast (void (double*)* @f to i8*), double* %x, %struct.Gradients %xp)
  ret %struct.Gradients %call
}

attributes #0 = { noinline norecurse nounwind uwtable }
attributes #1 = { noinline nounwind uwtable }


; CHECK: define internal void @fwdvectordiffef(double* nocapture %x, [3 x double*] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   call void @fwdvectordiffesubf(double* %x, [3 x double*] %"x'")
; CHECK-NEXT:   store double 2.000000e+00, double* %x, align 8
; CHECK-NEXT:   %0 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   store double 0.000000e+00, double* %0, align 8
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   store double 0.000000e+00, double* %1, align 8
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   store double 0.000000e+00, double* %2, align 8
; CHECK-NEXT:   ret void
; CHECK-NEXT: }

; CHECK: define internal void @fwdvectordiffesubf(double* nocapture %x, [3 x double*] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = load double, double* %x, align 8
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   %2 = load double, double* %1, align 8
; CHECK-NEXT:   %3 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   %4 = load double, double* %3, align 8
; CHECK-NEXT:   %5 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   %6 = load double, double* %5, align 8
; CHECK-NEXT:   %mul = fmul fast double %0, %0
; CHECK-NEXT:   %7 = insertelement <3 x double> undef, double %2, i64 0
; CHECK-NEXT:   %8 = insertelement <3 x double> %7, double %4, i64 1
; CHECK-NEXT:   %9 = insertelement <3 x double> %8, double %6, i64 2
; CHECK-NEXT:   %10 = insertelement <3 x double> undef, double %2, i64 0
; CHECK-NEXT:   %11 = insertelement <3 x double> %10, double %4, i64 1
; CHECK-NEXT:   %12 = insertelement <3 x double> %11, double %6, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{poison|undef}}, double %0, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %13 = fmul fast <3 x double> %9, %.splat
; CHECK-NEXT:   %.splatinsert1 = insertelement <3 x double> {{poison|undef}}, double %0, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <3 x double> %.splatinsert1, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %14 = fmul fast <3 x double> %12, %.splat2
; CHECK-NEXT:   %15 = fadd fast <3 x double> %13, %14
; CHECK-NEXT:   %16 = extractelement <3 x double> %15, i64 0
; CHECK-NEXT:   %17 = extractelement <3 x double> %15, i64 1
; CHECK-NEXT:   %18 = extractelement <3 x double> %15, i64 2
; CHECK-NEXT:   store double %mul, double* %x, align 8
; CHECK-NEXT:   %19 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   store double %16, double* %19, align 8
; CHECK-NEXT:   %20 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   store double %17, double* %20, align 8
; CHECK-NEXT:   %21 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   store double %18, double* %21, align 8
; CHECK-NEXT:   call void @fwdvectordiffemetasubf(double* %x, [3 x double*] %"x'")
; CHECK-NEXT:   ret void
; CHECK-NEXT: }

; CHECK: define internal void @fwdvectordiffemetasubf(double* nocapture %x, [3 x double*] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds double, double* %0, i64 1
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   %"arrayidx'ipg1" = getelementptr inbounds double, double* %1, i64 1
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   %"arrayidx'ipg2" = getelementptr inbounds double, double* %2, i64 1
; CHECK-NEXT:   %arrayidx = getelementptr inbounds double, double* %x, i64 1
; CHECK-NEXT:   store double 3.000000e+00, double* %arrayidx, align 8
; CHECK-NEXT:   store double 0.000000e+00, double* %"arrayidx'ipg", align 8
; CHECK-NEXT:   store double 0.000000e+00, double* %"arrayidx'ipg1", align 8
; CHECK-NEXT:   store double 0.000000e+00, double* %"arrayidx'ipg2", align 8
; CHECK-NEXT:   ret void
; CHECK-NEXT: }
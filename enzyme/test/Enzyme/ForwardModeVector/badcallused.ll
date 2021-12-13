; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -adce -correlated-propagation -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double*, double*, double* }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, double*, %struct.Gradients)

; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -adce -correlated-propagation -simplifycfg -S | FileCheck %s

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
  %mul = fmul fast double %0, 2.000000e+00
  store double %mul, double* %x, align 8
  %call = tail call zeroext i1 @metasubf(double* %x)
  ret i1 %call
}

; Function Attrs: noinline norecurse nounwind uwtable
define dso_local void @f(double* nocapture %x) #0 {
entry:
  %call = tail call zeroext i1 @subf(double* %x)
  %sel = select i1 %call, double 2.000000e+00, double 3.000000e+00
  store double %sel, double* %x, align 8
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
; CHECK-NEXT:   %0 = call i1 @fwdvectordiffesubf(double* %x, [3 x double*] %"x'")
; CHECK-NEXT:   %sel = select i1 %0, double 2.000000e+00, double 3.000000e+00
; CHECK-NEXT:   store double %sel, double* %x, align 8
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   store double 0.000000e+00, double* %1, align 8
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   store double 0.000000e+00, double* %2, align 8
; CHECK-NEXT:   %3 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   store double 0.000000e+00, double* %3, align 8
; CHECK-NEXT:   ret void
; CHECK-NEXT: }

; CHECK: define internal i1 @fwdvectordiffesubf(double* nocapture %x, [3 x double*] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = load double, double* %x, align 8
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   %2 = load double, double* %1, align 8
; CHECK-NEXT:   %3 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   %4 = load double, double* %3, align 8
; CHECK-NEXT:   %5 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   %6 = load double, double* %5, align 8
; CHECK-NEXT:   %mul = fmul fast double %0, 2.000000e+00
; CHECK-NEXT:   %7 = insertelement <3 x double> undef, double %2, i64 0
; CHECK-NEXT:   %8 = insertelement <3 x double> %7, double %4, i64 1
; CHECK-NEXT:   %9 = insertelement <3 x double> %8, double %6, i64 2
; CHECK-NEXT:   %10 = fmul fast <3 x double> %9, <double 2.000000e+00, double 2.000000e+00, double 2.000000e+00>
; CHECK-NEXT:   %11 = extractelement <3 x double> %10, i64 0
; CHECK-NEXT:   %12 = extractelement <3 x double> %10, i64 1
; CHECK-NEXT:   %13 = extractelement <3 x double> %10, i64 2
; CHECK-NEXT:   store double %mul, double* %x, align 8
; CHECK-NEXT:   %14 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   store double %11, double* %14, align 8
; CHECK-NEXT:   %15 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   store double %12, double* %15, align 8
; CHECK-NEXT:   %16 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   store double %13, double* %16, align 8
; CHECK-NEXT:   %17 = call i1 @fwdvectordiffemetasubf(double* %x, [3 x double*] %"x'")
; CHECK-NEXT:   ret i1 %17
; CHECK-NEXT: }

; CHECK: define internal i1 @fwdvectordiffemetasubf(double* nocapture %x, [3 x double*] %"x'")
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
; CHECK-NEXT:   %3 = load double, double* %x, align 8
; CHECK-NEXT:   %cmp = fcmp fast oeq double %3, 2.000000e+00
; CHECK-NEXT:   ret i1 %cmp
; CHECK-NEXT: }
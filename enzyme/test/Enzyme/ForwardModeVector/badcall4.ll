; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -sroa -instsimplify -adce -correlated-propagation -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, double*, %struct.Gradients*)


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
define dso_local zeroext i1 @othermetasubf(double* nocapture %x) local_unnamed_addr #0 {
entry:
  %arrayidx = getelementptr inbounds double, double* %x, i64 1
  store double 4.000000e+00, double* %arrayidx, align 8
  %0 = load double, double* %x, align 8
  %cmp = fcmp fast oeq double %0, 3.000000e+00
  ret i1 %cmp
}

; Function Attrs: noinline norecurse nounwind uwtable
define dso_local zeroext i1 @subf(double* nocapture %x) local_unnamed_addr #0 {
entry:
  %0 = load double, double* %x, align 8
  %mul = fmul fast double %0, 2.000000e+00
  store double %mul, double* %x, align 8
  %call = tail call zeroext i1 @metasubf(double* %x)
  %call1 = tail call zeroext i1 @othermetasubf(double* %x)
  %res = and i1 %call, %call1
  ret i1 %res
}

; Function Attrs: noinline norecurse nounwind uwtable
define dso_local void @f(double* nocapture %x) #0 {
entry:
  %call = tail call zeroext i1 @subf(double* %x)
  store double 2.000000e+00, double* %x, align 8
  ret void
}

; Function Attrs: noinline nounwind uwtable
define dso_local %struct.Gradients @dsumsquare(double* %x, %struct.Gradients* %xp) local_unnamed_addr #1 {
entry:
  %call = tail call %struct.Gradients @__enzyme_fwdvectordiff(i8* bitcast (void (double*)* @f to i8*), double* %x, %struct.Gradients* %xp)
  ret %struct.Gradients %call
}


; CHECK: define internal {{(dso_local )?}}void @fwdvectordiffef(double* nocapture %x, <3 x double>* nocapture %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   call void @fwdvectordiffesubf(double* %x, <3 x double>* %"x'")
; CHECK-NEXT:   store double 2.000000e+00, double* %x, align 8
; CHECK-NEXT:   store <3 x double> zeroinitializer, <3 x double>* %"x'", align 8
; CHECK-NEXT:   ret void
; CHECK-NEXT: }

; CHECK: define internal {{(dso_local )?}}void @fwdvectordiffesubf(double* nocapture %x, <3 x double>* nocapture %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = load double, double* %x, align 8
; CHECK-NEXT:   %1 = load <3 x double>, <3 x double>* %"x'", align 8
; CHECK-NEXT:   %mul = fmul fast double %0, 2.000000e+00
; CHECK-NEXT:   %2 = fmul fast <3 x double> %1, <double 2.000000e+00, double 2.000000e+00, double 2.000000e+00>
; CHECK-NEXT:   store double %mul, double* %x, align 8
; CHECK-NEXT:   store <3 x double> %2, <3 x double>* %"x'", align 8
; CHECK-NEXT:   call void @fwdvectordiffemetasubf(double* %x, <3 x double>* %"x'")
; CHECK-NEXT:   call void @fwdvectordiffeothermetasubf(double* %x, <3 x double>* %"x'")
; CHECK-NEXT:   ret void
; CHECK-NEXT: }

; CHECK: define internal {{(dso_local )?}}void @fwdvectordiffemetasubf(double* nocapture %x, <3 x double>* nocapture %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds <3 x double>, <3 x double>* %"x'", i64 1
; CHECK-NEXT:   %arrayidx = getelementptr inbounds double, double* %x, i64 1
; CHECK-NEXT:   store double 3.000000e+00, double* %arrayidx, align 8
; CHECK-NEXT:   store <3 x double> zeroinitializer, <3 x double>* %"arrayidx'ipg", align 8
; CHECK-NEXT:   ret void
; CHECK-NEXT: }


; CHECK: define internal {{(dso_local )?}}void @fwdvectordiffeothermetasubf(double* nocapture %x, <3 x double>* nocapture %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds <3 x double>, <3 x double>* %"x'", i64 1
; CHECK-NEXT:   %arrayidx = getelementptr inbounds double, double* %x, i64 1
; CHECK-NEXT:   store double 4.000000e+00, double* %arrayidx, align 8
; CHECK-NEXT:   store <3 x double> zeroinitializer, <3 x double>* %"arrayidx'ipg", align 8
; CHECK-NEXT:   ret void
; CHECK-NEXT: }
; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -inline -mem2reg -instsimplify -adce -loop-deletion -correlated-propagation -simplifycfg -early-cse -S | FileCheck %s

%struct.InGradients = type { double*, double*, double* }
%struct.OutGradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.OutGradients @__enzyme_fwdvectordiff(double (double*, i64)*, ...)

; Function Attrs: norecurse nounwind readonly uwtable
define dso_local double @sumsquare(double* nocapture readonly %x, i64 %n) #0 {
entry:
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body
  ret double %add

for.body:                                         ; preds = %entry, %for.body
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %total.011 = phi double [ 0.000000e+00, %entry ], [ %add, %for.body ]
  %arrayidx = getelementptr inbounds double, double* %x, i64 %indvars.iv
  %0 = load double, double* %arrayidx, align 8
  %mul = fmul fast double %0, %0
  %add = fadd fast double %mul, %total.011
  %indvars.iv.next = add nuw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv, %n
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

; Function Attrs: nounwind uwtable
define dso_local %struct.OutGradients @dsumsquare(double* %x, %struct.InGradients %xp, i64 %n) local_unnamed_addr #1 {
entry:
  %0 = tail call %struct.OutGradients (double (double*, i64)*, ...) @__enzyme_fwdvectordiff(double (double*, i64)* nonnull @sumsquare, double* %x, %struct.InGradients %xp, i64 %n)
  ret %struct.OutGradients %0
}


attributes #0 = { norecurse nounwind readonly uwtable }
attributes #1 = { nounwind uwtable }
attributes #2 = { nounwind }


; CHECK: define dso_local %struct.OutGradients @dsumsquare(double* %x, %struct.InGradients %xp, i64 %n)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue %struct.InGradients %xp, 0
; CHECK-NEXT:   %1 = extractvalue %struct.InGradients %xp, 1
; CHECK-NEXT:   %2 = extractvalue %struct.InGradients %xp, 2
; CHECK-NEXT:   br label %for.body.i

; CHECK: for.body.i:                                       ; preds = %for.body.i, %entry
; CHECK-NEXT:   %iv.i = phi i64 [ %iv.next.i, %for.body.i ], [ 0, %entry ]
; CHECK-NEXT:   %"total.011'.i" = phi {{(fast )?}}[3 x double] [ zeroinitializer, %entry ], [ %30, %for.body.i ]
; CHECK-NEXT:   %iv.next.i = add nuw nsw i64 %iv.i, 1
; CHECK-NEXT:   %"arrayidx'ipg.i" = getelementptr inbounds double, double* %0, i64 %iv.i
; CHECK-NEXT:   %"arrayidx'ipg1.i" = getelementptr inbounds double, double* %1, i64 %iv.i
; CHECK-NEXT:   %"arrayidx'ipg2.i" = getelementptr inbounds double, double* %2, i64 %iv.i
; CHECK-NEXT:   %arrayidx.i = getelementptr inbounds double, double* %x, i64 %iv.i
; CHECK-NEXT:   %3 = load double, double* %arrayidx.i, align 8
; CHECK-NEXT:   %4 = load double, double* %"arrayidx'ipg.i", align 8
; CHECK-NEXT:   %5 = load double, double* %"arrayidx'ipg1.i", align 8
; CHECK-NEXT:   %6 = load double, double* %"arrayidx'ipg2.i", align 8
; CHECK-NEXT:   %7 = insertelement <3 x double> undef, double %4, i64 0
; CHECK-NEXT:   %8 = insertelement <3 x double> %7, double %5, i64 1
; CHECK-NEXT:   %9 = insertelement <3 x double> %8, double %6, i64 2
; CHECK-NEXT:   %.splatinsert.i = insertelement <3 x double> {{poison|undef}}, double %3, i32 0
; CHECK-NEXT:   %.splat.i = shufflevector <3 x double> %.splatinsert.i, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %10 = fmul fast <3 x double> %9, %.splat.i
; CHECK-NEXT:   %11 = fadd fast <3 x double> %10, %10
; CHECK-NEXT:   %12 = extractelement <3 x double> %11, i64 0
; CHECK-NEXT:   %13 = extractelement <3 x double> %11, i64 1
; CHECK-NEXT:   %14 = extractelement <3 x double> %11, i64 2
; CHECK-NEXT:   %15 = insertelement <3 x double> undef, double %12, i64 0
; CHECK-NEXT:   %16 = insertelement <3 x double> %15, double %13, i64 1
; CHECK-NEXT:   %17 = insertelement <3 x double> %16, double %14, i64 2
; CHECK-NEXT:   %18 = extractvalue [3 x double] %"total.011'.i", 0
; CHECK-NEXT:   %19 = insertelement <3 x double> undef, double %18, i64 0
; CHECK-NEXT:   %20 = extractvalue [3 x double] %"total.011'.i", 1
; CHECK-NEXT:   %21 = insertelement <3 x double> %19, double %20, i64 1
; CHECK-NEXT:   %22 = extractvalue [3 x double] %"total.011'.i", 2
; CHECK-NEXT:   %23 = insertelement <3 x double> %21, double %22, i64 2
; CHECK-NEXT:   %24 = fadd fast <3 x double> %17, %23
; CHECK-NEXT:   %25 = extractelement <3 x double> %24, i64 0
; CHECK-NEXT:   %26 = insertvalue [3 x double] undef, double %25, 0
; CHECK-NEXT:   %27 = extractelement <3 x double> %24, i64 1
; CHECK-NEXT:   %28 = insertvalue [3 x double] %26, double %27, 1
; CHECK-NEXT:   %29 = extractelement <3 x double> %24, i64 2
; CHECK-NEXT:   %30 = insertvalue [3 x double] %28, double %29, 2
; CHECK-NEXT:   %exitcond.i = icmp eq i64 %iv.i, %n
; CHECK-NEXT:   br i1 %exitcond.i, label %fwdvectordiffesumsquare.exit, label %for.body.i

; CHECK: fwdvectordiffesumsquare.exit:                     ; preds = %for.body.i
; CHECK-NEXT:   %31 = insertvalue %struct.OutGradients zeroinitializer, double %25, 0
; CHECK-NEXT:   %32 = insertvalue %struct.OutGradients %31, double %27, 1
; CHECK-NEXT:   %33 = insertvalue %struct.OutGradients %32, double %29, 2
; CHECK-NEXT:   ret %struct.OutGradients %33
; CHECK-NEXT: }
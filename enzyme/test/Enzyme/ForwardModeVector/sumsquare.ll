; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -inline -mem2reg -instsimplify -adce -loop-deletion -correlated-propagation -simplifycfg -early-cse -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double*, i64)*, ...)

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
define dso_local %struct.Gradients @dsumsquare(double* %x, %struct.Gradients* %xp, i64 %n) local_unnamed_addr #1 {
entry:
  %0 = tail call %struct.Gradients (double (double*, i64)*, ...) @__enzyme_fwdvectordiff(double (double*, i64)* nonnull @sumsquare, double* %x, %struct.Gradients* %xp, i64 %n)
  ret %struct.Gradients %0
}


attributes #0 = { norecurse nounwind readonly uwtable }
attributes #1 = { nounwind uwtable }
attributes #2 = { nounwind }



; CHECK: define {{(dso_local )?}}%struct.Gradients @dsumsquare(double* %x, %struct.Gradients* %xp, i64 %n)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = alloca <3 x double>, align 32
; CHECK-NEXT:   %1 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %xp, i32 0, i32 0
; CHECK-NEXT:   %2 = load double, double* %1, align 8
; CHECK-NEXT:   %3 = insertelement <3 x double> undef, double %2, i64 0
; CHECK-NEXT:   %4 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %xp, i32 0, i32 1
; CHECK-NEXT:   %5 = load double, double* %4, align 8
; CHECK-NEXT:   %6 = insertelement <3 x double> %3, double %5, i64 1
; CHECK-NEXT:   %7 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %xp, i32 0, i32 2
; CHECK-NEXT:   %8 = load double, double* %7, align 8
; CHECK-NEXT:   %9 = insertelement <3 x double> %6, double %8, i64 2
; CHECK-NEXT:   store <3 x double> %9, <3 x double>* %0, align 32
; CHECK-NEXT:   br label %for.body.i

; CHECK: for.body.i:                                       ; preds = %for.body.i, %entry
; CHECK-NEXT:   %iv.i = phi i64 [ %iv.next.i, %for.body.i ], [ 0, %entry ]
; CHECK-NEXT:   %"total.011'.i" = phi fast <3 x double> [ zeroinitializer, %entry ], [ %14, %for.body.i ]
; CHECK-NEXT:   %iv.next.i = add nuw nsw i64 %iv.i, 1
; CHECK-NEXT:   %"arrayidx'ipg.i" = getelementptr inbounds <3 x double>, <3 x double>* %0, i64 %iv.i
; CHECK-NEXT:   %arrayidx.i = getelementptr inbounds double, double* %x, i64 %iv.i
; CHECK-NEXT:   %10 = load double, double* %arrayidx.i, align 8
; CHECK-NEXT:   %11 = load <3 x double>, <3 x double>* %"arrayidx'ipg.i", align 8
; CHECK-NEXT:   %.splatinsert.i = insertelement <3 x double> poison, double %10, i32 0
; CHECK-NEXT:   %.splat.i = shufflevector <3 x double> %.splatinsert.i, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %12 = fmul fast <3 x double> %11, %.splat.i
; CHECK-NEXT:   %13 = fadd fast <3 x double> %12, %12
; CHECK-NEXT:   %14 = fadd fast <3 x double> %13, %"total.011'.i"
; CHECK-NEXT:   %exitcond.i = icmp eq i64 %iv.i, %n
; CHECK-NEXT:   br i1 %exitcond.i, label %fwdvectordiffesumsquare.exit, label %for.body.i

; CHECK: fwdvectordiffesumsquare.exit:                     ; preds = %for.body.i
; CHECK-NEXT:   %15 = extractelement <3 x double> %14, i64 0
; CHECK-NEXT:   %16 = insertvalue %struct.Gradients zeroinitializer, double %15, 0
; CHECK-NEXT:   %17 = extractelement <3 x double> %14, i64 1
; CHECK-NEXT:   %18 = insertvalue %struct.Gradients %16, double %17, 1
; CHECK-NEXT:   %19 = extractelement <3 x double> %14, i64 2
; CHECK-NEXT:   %20 = insertvalue %struct.Gradients %18, double %19, 2
; CHECK-NEXT:   %21 = load <3 x double>, <3 x double>* %0, align 32
; CHECK-NEXT:   %22 = extractelement <3 x double> %21, i64 0
; CHECK-NEXT:   store double %22, double* %1, align 8
; CHECK-NEXT:   %23 = extractelement <3 x double> %21, i64 1
; CHECK-NEXT:   store double %23, double* %4, align 8
; CHECK-NEXT:   %24 = extractelement <3 x double> %21, i64 2
; CHECK-NEXT:   store double %24, double* %7, align 8
; CHECK-NEXT:   ret %struct.Gradients %20
; CHECK-NEXT: }
; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instcombine -correlated-propagation -adce -instcombine -simplifycfg -early-cse -simplifycfg -loop-unroll -instcombine -simplifycfg -gvn -jump-threading -instcombine -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, double*, %struct.Gradients*, i64)

; Function Attrs: noinline nounwind uwtable
define dso_local double @f(double* nocapture readonly %x, i64 %n) #0 {
entry:
  br label %for.body

for.body:                                         ; preds = %if.end, %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %if.end ]
  %data.016 = phi double [ 0.000000e+00, %entry ], [ %add5, %if.end ]
  %cmp2 = fcmp fast ogt double %data.016, 1.000000e+01
  br i1 %cmp2, label %if.then, label %if.end

if.then:                                          ; preds = %for.body
  %arrayidx = getelementptr inbounds double, double* %x, i64 %n
  %0 = load double, double* %arrayidx, align 8
  %add = fadd fast double %0, %data.016
  br label %cleanup

if.end:                                           ; preds = %for.body
  %arrayidx4 = getelementptr inbounds double, double* %x, i64 %indvars.iv
  %1 = load double, double* %arrayidx4, align 8
  %add5 = fadd fast double %1, %data.016
  %indvars.iv.next = add nuw i64 %indvars.iv, 1
  %cmp = icmp ult i64 %indvars.iv, %n
  br i1 %cmp, label %for.body, label %cleanup

cleanup:                                          ; preds = %if.end, %if.then
  %data.1 = phi double [ %add, %if.then ], [ %add5, %if.end ]
  ret double %data.1
}

; Function Attrs: noinline nounwind uwtable
define dso_local %struct.Gradients @dsumsquare(double* %x, %struct.Gradients* %xp, i64 %n) #0 {
entry:
  %call = call %struct.Gradients @__enzyme_fwdvectordiff(i8* bitcast (double (double*, i64)* @f to i8*), double* %x, %struct.Gradients* %xp, i64 %n)
  ret %struct.Gradients %call
}


attributes #0 = { noinline nounwind uwtable }


; CHECK: define internal <3 x double> @fwdvectordiffef(double* nocapture readonly %x, <3 x double>* nocapture %"x'", i64 %n)
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %for.body

; CHECK: for.body:                                         ; preds = %if.end, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %if.end ], [ 0, %entry ]
; CHECK-NEXT:   %data.016 = phi double [ %add5, %if.end ], [ 0.000000e+00, %entry ]
; CHECK-NEXT:   %"data.016'" = phi fast <3 x double> [ %4, %if.end ], [ zeroinitializer, %entry ]
; CHECK-NEXT:   %cmp2 = fcmp fast ogt double %data.016, 1.000000e+01
; CHECK-NEXT:   br i1 %cmp2, label %if.then, label %if.end

; CHECK: if.then:                                          ; preds = %for.body
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds <3 x double>, <3 x double>* %"x'", i64 %n
; CHECK-NEXT:   %0 = load <3 x double>, <3 x double>* %"arrayidx'ipg", align 8
; CHECK-NEXT:   %1 = fadd fast <3 x double> %0, %"data.016'"
; CHECK-NEXT:   br label %cleanup

; CHECK: if.end:                                           ; preds = %for.body
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %"arrayidx4'ipg" = getelementptr inbounds <3 x double>, <3 x double>* %"x'", i64 %iv
; CHECK-NEXT:   %arrayidx4 = getelementptr inbounds double, double* %x, i64 %iv
; CHECK-NEXT:   %2 = load double, double* %arrayidx4, align 8
; CHECK-NEXT:   %3 = load <3 x double>, <3 x double>* %"arrayidx4'ipg", align 8
; CHECK-NEXT:   %add5 = fadd fast double %2, %data.016
; CHECK-NEXT:   %4 = fadd fast <3 x double> %3, %"data.016'"
; CHECK-NEXT:   %cmp = icmp ult i64 %iv, %n
; CHECK-NEXT:   br i1 %cmp, label %for.body, label %cleanup

; CHECK: cleanup:                                          ; preds = %if.end, %if.then
; CHECK-NEXT:   %"data.1'" = phi fast <3 x double> [ %1, %if.then ], [ %4, %if.end ]
; CHECK-NEXT:   ret <3 x double> %"data.1'"
; CHECK-NEXT: }
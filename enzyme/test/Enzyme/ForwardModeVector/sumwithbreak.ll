; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instcombine -correlated-propagation -adce -instcombine -simplifycfg -early-cse -simplifycfg -loop-unroll -instcombine -simplifycfg -gvn -jump-threading -instcombine -simplifycfg -S | FileCheck %s

%struct.InGradients = type { double*, double*, double* }
%struct.OutGradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.OutGradients @__enzyme_fwdvectordiff(i8*, double*, %struct.InGradients, i64)

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
define dso_local %struct.OutGradients @dsumsquare(double* %x, %struct.InGradients %xp, i64 %n) #0 {
entry:
  %call = call %struct.OutGradients @__enzyme_fwdvectordiff(i8* bitcast (double (double*, i64)* @f to i8*), double* %x, %struct.InGradients %xp, i64 %n)
  ret %struct.OutGradients %call
}


attributes #0 = { noinline nounwind uwtable }


; CHECK: define internal [3 x double] @fwdvectordiffef(double* nocapture readonly %x, [3 x double*] %"x'", i64 %n)
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %for.body

; CHECK: for.body:                                         ; preds = %if.end, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %if.end ], [ 0, %entry ]
; CHECK-NEXT:   %data.016 = phi double [ %add5, %if.end ], [ 0.000000e+00, %entry ]
; CHECK-NEXT:   %"data.016'" = phi {{(fast )?}}[3 x double] [ %44, %if.end ], [ zeroinitializer, %entry ]
; CHECK-NEXT:   %cmp2 = fcmp fast ogt double %data.016, 1.000000e+01
; CHECK-NEXT:   br i1 %cmp2, label %if.then, label %if.end

; CHECK: if.then:                                          ; preds = %for.body
; CHECK-NEXT:   %0 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds double, double* %0, i64 %n
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   %"arrayidx'ipg1" = getelementptr inbounds double, double* %1, i64 %n
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   %"arrayidx'ipg2" = getelementptr inbounds double, double* %2, i64 %n
; CHECK-NEXT:   %3 = load double, double* %"arrayidx'ipg", align 8
; CHECK-NEXT:   %4 = load double, double* %"arrayidx'ipg1", align 8
; CHECK-NEXT:   %5 = load double, double* %"arrayidx'ipg2", align 8
; CHECK-NEXT:   %6 = insertelement <3 x double> undef, double %3, i64 0
; CHECK-NEXT:   %7 = insertelement <3 x double> %6, double %4, i64 1
; CHECK-NEXT:   %8 = insertelement <3 x double> %7, double %5, i64 2
; CHECK-NEXT:   %9 = extractvalue [3 x double] %"data.016'", 0
; CHECK-NEXT:   %10 = insertelement <3 x double> undef, double %9, i64 0
; CHECK-NEXT:   %11 = extractvalue [3 x double] %"data.016'", 1
; CHECK-NEXT:   %12 = insertelement <3 x double> %10, double %11, i64 1
; CHECK-NEXT:   %13 = extractvalue [3 x double] %"data.016'", 2
; CHECK-NEXT:   %14 = insertelement <3 x double> %12, double %13, i64 2
; CHECK-NEXT:   %15 = fadd fast <3 x double> %8, %14
; CHECK-NEXT:   %16 = extractelement <3 x double> %15, i64 0
; CHECK-NEXT:   %17 = insertvalue [3 x double] undef, double %16, 0
; CHECK-NEXT:   %18 = extractelement <3 x double> %15, i64 1
; CHECK-NEXT:   %19 = insertvalue [3 x double] %17, double %18, 1
; CHECK-NEXT:   %20 = extractelement <3 x double> %15, i64 2
; CHECK-NEXT:   %21 = insertvalue [3 x double] %19, double %20, 2
; CHECK-NEXT:   br label %cleanup

; CHECK: if.end:                                           ; preds = %for.body
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %22 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   %"arrayidx4'ipg" = getelementptr inbounds double, double* %22, i64 %iv
; CHECK-NEXT:   %23 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   %"arrayidx4'ipg3" = getelementptr inbounds double, double* %23, i64 %iv
; CHECK-NEXT:   %24 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   %"arrayidx4'ipg4" = getelementptr inbounds double, double* %24, i64 %iv
; CHECK-NEXT:   %arrayidx4 = getelementptr inbounds double, double* %x, i64 %iv
; CHECK-NEXT:   %25 = load double, double* %arrayidx4, align 8
; CHECK-NEXT:   %26 = load double, double* %"arrayidx4'ipg", align 8
; CHECK-NEXT:   %27 = load double, double* %"arrayidx4'ipg3", align 8
; CHECK-NEXT:   %28 = load double, double* %"arrayidx4'ipg4", align 8
; CHECK-NEXT:   %add5 = fadd fast double %25, %data.016
; CHECK-NEXT:   %29 = insertelement <3 x double> undef, double %26, i64 0
; CHECK-NEXT:   %30 = insertelement <3 x double> %29, double %27, i64 1
; CHECK-NEXT:   %31 = insertelement <3 x double> %30, double %28, i64 2
; CHECK-NEXT:   %32 = extractvalue [3 x double] %"data.016'", 0
; CHECK-NEXT:   %33 = insertelement <3 x double> undef, double %32, i64 0
; CHECK-NEXT:   %34 = extractvalue [3 x double] %"data.016'", 1
; CHECK-NEXT:   %35 = insertelement <3 x double> %33, double %34, i64 1
; CHECK-NEXT:   %36 = extractvalue [3 x double] %"data.016'", 2
; CHECK-NEXT:   %37 = insertelement <3 x double> %35, double %36, i64 2
; CHECK-NEXT:   %38 = fadd fast <3 x double> %31, %37
; CHECK-NEXT:   %39 = extractelement <3 x double> %38, i64 0
; CHECK-NEXT:   %40 = insertvalue [3 x double] undef, double %39, 0
; CHECK-NEXT:   %41 = extractelement <3 x double> %38, i64 1
; CHECK-NEXT:   %42 = insertvalue [3 x double] %40, double %41, 1
; CHECK-NEXT:   %43 = extractelement <3 x double> %38, i64 2
; CHECK-NEXT:   %44 = insertvalue [3 x double] %42, double %43, 2
; CHECK-NEXT:   %cmp = icmp ult i64 %iv, %n
; CHECK-NEXT:   br i1 %cmp, label %for.body, label %cleanup

; CHECK: cleanup:                                          ; preds = %if.end, %if.then
; CHECK-NEXT:   %"data.1'" = phi {{(fast )?}}[3 x double] [ %21, %if.then ], [ %44, %if.end ]
; CHECK-NEXT:   ret [3 x double] %"data.1'"
; CHECK-NEXT: }
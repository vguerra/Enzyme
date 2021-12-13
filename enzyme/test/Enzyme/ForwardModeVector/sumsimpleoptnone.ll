; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -inline -mem2reg -instsimplify -adce -loop-deletion -correlated-propagation -simplifycfg -S -early-cse | FileCheck %s

%struct.InGradients1 = type { double*, double*, double* }
%struct.InGradients2 = type { double**, double**, double** }
%struct.OutGradients = type { double, double, double }

; Function Attrs: noinline nounwind uwtable
define dso_local void @f(double* %x, double** %y, i64 %n) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.body, %entry
  %i.0 = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %cmp = icmp ule i64 %i.0, %n
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds double, double* %x, i64 0
  %0 = load double, double* %arrayidx
  %1 = load double*, double** %y
  %2 = load double, double* %1
  %add = fadd fast double %2, %0
  store double %add, double* %1
  %inc = add i64 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: noinline nounwind uwtable
define dso_local %struct.OutGradients @dsumsquare(double* %x, %struct.InGradients1 %xp, double** %y, %struct.InGradients2 %yp, i64 %n) #0 {
entry:
  %call = call %struct.OutGradients @__enzyme_fwdvectordiff(i8* bitcast (void (double*, double**, i64)* @f to i8*), double* %x, %struct.InGradients1 %xp, double** %y, %struct.InGradients2 %yp, i64 %n)
  ret %struct.OutGradients %call
}

declare %struct.OutGradients @__enzyme_fwdvectordiff(i8*, double*, %struct.InGradients1, double**, %struct.InGradients2, i64)


attributes #0 = { noinline nounwind uwtable optnone }


; CHECK: define internal void @fwdvectordiffef(double* %x, [3 x double*] %"x'", double** %y, [3 x double**] %"y'", i64 %n) #1 {
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = add nuw i64 %n, 1
; CHECK-NEXT:   br label %for.cond

; CHECK: for.cond:                                         ; preds = %for.body, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %for.body ], [ 0, %entry ]
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %cmp = icmp ne i64 %iv, %0
; CHECK-NEXT:   br i1 %cmp, label %for.body, label %for.end

; CHECK: for.body:                                         ; preds = %for.cond
; CHECK-NEXT:   %1 = load double, double* %x
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   %3 = load double, double* %2
; CHECK-NEXT:   %4 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   %5 = load double, double* %4
; CHECK-NEXT:   %6 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   %7 = load double, double* %6
; CHECK-NEXT:   %8 = extractvalue [3 x double**] %"y'", 0
; CHECK-NEXT:   %"'ipl" = load double*, double** %8
; CHECK-NEXT:   %9 = extractvalue [3 x double**] %"y'", 1
; CHECK-NEXT:   %"'ipl3" = load double*, double** %9
; CHECK-NEXT:   %10 = extractvalue [3 x double**] %"y'", 2
; CHECK-NEXT:   %"'ipl4" = load double*, double** %10
; CHECK-NEXT:   %11 = load double*, double** %y
; CHECK-NEXT:   %12 = load double, double* %11
; CHECK-NEXT:   %13 = load double, double* %"'ipl"
; CHECK-NEXT:   %14 = load double, double* %"'ipl3"
; CHECK-NEXT:   %15 = load double, double* %"'ipl4"
; CHECK-NEXT:   %add = fadd fast double %12, %1
; CHECK-NEXT:   %16 = insertelement <3 x double> undef, double %13, i64 0
; CHECK-NEXT:   %17 = insertelement <3 x double> %16, double %14, i64 1
; CHECK-NEXT:   %18 = insertelement <3 x double> %17, double %15, i64 2
; CHECK-NEXT:   %19 = insertelement <3 x double> undef, double %3, i64 0
; CHECK-NEXT:   %20 = insertelement <3 x double> %19, double %5, i64 1
; CHECK-NEXT:   %21 = insertelement <3 x double> %20, double %7, i64 2
; CHECK-NEXT:   %22 = fadd fast <3 x double> %18, %21
; CHECK-NEXT:   %23 = extractelement <3 x double> %22, i64 0
; CHECK-NEXT:   %24 = extractelement <3 x double> %22, i64 1
; CHECK-NEXT:   %25 = extractelement <3 x double> %22, i64 2
; CHECK-NEXT:   store double %add, double* %11
; CHECK-NEXT:   store double %23, double* %"'ipl"
; CHECK-NEXT:   store double %24, double* %"'ipl3"
; CHECK-NEXT:   store double %25, double* %"'ipl4"
; CHECK-NEXT:   br label %for.cond

; CHECK: for.end:                                          ; preds = %for.cond
; CHECK-NEXT:   ret void
; CHECK-NEXT: }
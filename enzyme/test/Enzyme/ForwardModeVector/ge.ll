; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -adce -loop-deletion -correlated-propagation -simplifycfg -early-cse -S | FileCheck %s

%struct.InGradients = type { double*, double*, double* }
%struct.OutGradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.OutGradients @__enzyme_fwdvectordiff(i8*, ...)

; void __enzyme_autodiff(void*, ...);

; double cache(double* x, unsigned N) {
;     double sum = 0.0;
;     for(unsigned i=0; i<=N; i++) {
;         sum += x[i] * x[i];
;     }
;     x[0] = 0.0;
;     return sum;
; }

; void ad(double* in, double* din, unsigned N) {
;     __enzyme_autodiff(cache, in, din, N);
; }

; ModuleID = 'foo.c'
; source_filename = "foo.c"
; target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
; target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: norecurse nounwind uwtable
define dso_local double @cache(double* nocapture %x, i32 %N) #0 {
entry:
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body
  store double 0.000000e+00, double* %x, align 8, !tbaa !2
  ret double %add

for.body:                                         ; preds = %entry, %for.body
  %i.013 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %sum.012 = phi double [ 0.000000e+00, %entry ], [ %add, %for.body ]
  %idxprom = zext i32 %i.013 to i64
  %arrayidx = getelementptr inbounds double, double* %x, i64 %idxprom
  %0 = load double, double* %arrayidx, align 8, !tbaa !2
  %mul = fmul double %0, %0
  %add = fadd double %sum.012, %mul
  %inc = add i32 %i.013, 1
  %cmp = icmp ugt i32 %inc, %N
  br i1 %cmp, label %for.cond.cleanup, label %for.body
}

; Function Attrs: nounwind uwtable
define dso_local void @ad(double* %in, %struct.InGradients %din, i32 %N) local_unnamed_addr #1 {
entry:
  tail call %struct.OutGradients (i8*, ...) @__enzyme_fwdvectordiff(i8* bitcast (double (double*, i32)* @cache to i8*), double* %in, %struct.InGradients %din, i32 %N) #3
  ret void
}

attributes #0 = { norecurse nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 7.0.0 (trunk 336729)"}
!2 = !{!3, !3, i64 0}
!3 = !{!"double", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}


; CHECK: define internal [3 x double] @fwdvectordiffecache(double* nocapture %x, [3 x double*] %"x'", i32 %N)
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %for.body

; CHECK: for.cond.cleanup:                                 ; preds = %for.body
; CHECK-NEXT:   store double 0.000000e+00, double* %x, align 8, !tbaa !2
; CHECK-NEXT:   store double 0.000000e+00, double* %1, align 8
; CHECK-NEXT:   store double 0.000000e+00, double* %2, align 8
; CHECK-NEXT:   store double 0.000000e+00, double* %3, align 8
; CHECK-NEXT:   ret [3 x double] %31

; CHECK: for.body:                                         ; preds = %for.body, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %for.body ], [ 0, %entry ]
; CHECK-NEXT:   %"sum.012'" = phi {{(fast )?}}[3 x double] [ zeroinitializer, %entry ], [ %31, %for.body ]
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %0 = trunc i64 %iv to i32
; CHECK-NEXT:   %idxprom = zext i32 %0 to i64
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds double, double* %1, i64 %idxprom
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   %"arrayidx'ipg1" = getelementptr inbounds double, double* %2, i64 %idxprom
; CHECK-NEXT:   %3 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   %"arrayidx'ipg2" = getelementptr inbounds double, double* %3, i64 %idxprom
; CHECK-NEXT:   %arrayidx = getelementptr inbounds double, double* %x, i64 %idxprom
; CHECK-NEXT:   %4 = load double, double* %arrayidx, align 8, !tbaa !2
; CHECK-NEXT:   %5 = load double, double* %"arrayidx'ipg", align 8
; CHECK-NEXT:   %6 = load double, double* %"arrayidx'ipg1", align 8
; CHECK-NEXT:   %7 = load double, double* %"arrayidx'ipg2", align 8
; CHECK-NEXT:   %8 = insertelement <3 x double> undef, double %5, i64 0
; CHECK-NEXT:   %9 = insertelement <3 x double> %8, double %6, i64 1
; CHECK-NEXT:   %10 = insertelement <3 x double> %9, double %7, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{poison|undef}}, double %4, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %11 = fmul fast <3 x double> %10, %.splat
; CHECK-NEXT:   %12 = fadd fast <3 x double> %11, %11
; CHECK-NEXT:   %13 = extractelement <3 x double> %12, i64 0
; CHECK-NEXT:   %14 = extractelement <3 x double> %12, i64 1
; CHECK-NEXT:   %15 = extractelement <3 x double> %12, i64 2
; CHECK-NEXT:   %16 = extractvalue [3 x double] %"sum.012'", 0
; CHECK-NEXT:   %17 = insertelement <3 x double> undef, double %16, i64 0
; CHECK-NEXT:   %18 = extractvalue [3 x double] %"sum.012'", 1
; CHECK-NEXT:   %19 = insertelement <3 x double> %17, double %18, i64 1
; CHECK-NEXT:   %20 = extractvalue [3 x double] %"sum.012'", 2
; CHECK-NEXT:   %21 = insertelement <3 x double> %19, double %20, i64 2
; CHECK-NEXT:   %22 = insertelement <3 x double> undef, double %13, i64 0
; CHECK-NEXT:   %23 = insertelement <3 x double> %22, double %14, i64 1
; CHECK-NEXT:   %24 = insertelement <3 x double> %23, double %15, i64 2
; CHECK-NEXT:   %25 = fadd fast <3 x double> %21, %24
; CHECK-NEXT:   %26 = extractelement <3 x double> %25, i64 0
; CHECK-NEXT:   %27 = insertvalue [3 x double] undef, double %26, 0
; CHECK-NEXT:   %28 = extractelement <3 x double> %25, i64 1
; CHECK-NEXT:   %29 = insertvalue [3 x double] %27, double %28, 1
; CHECK-NEXT:   %30 = extractelement <3 x double> %25, i64 2
; CHECK-NEXT:   %31 = insertvalue [3 x double] %29, double %30, 2
; CHECK-NEXT:   %inc = add i32 %0, 1
; CHECK-NEXT:   %cmp = icmp ugt i32 %inc, %N
; CHECK-NEXT:   br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK-NEXT: }
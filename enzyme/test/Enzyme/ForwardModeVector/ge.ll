; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -adce -loop-deletion -correlated-propagation -simplifycfg -early-cse -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, ...)

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
define dso_local void @ad(double* %in, %struct.Gradients* %din, i32 %N) local_unnamed_addr #1 {
entry:
  tail call %struct.Gradients (i8*, ...) @__enzyme_fwdvectordiff(i8* bitcast (double (double*, i32)* @cache to i8*), double* %in, %struct.Gradients* %din, i32 %N) #3
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


; CHECK: define internal <3 x double> @fwdvectordiffecache(double* nocapture %x, <3 x double>* nocapture %"x'", i32 %N) #0 {
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %for.body

; CHECK: for.cond.cleanup:                                 ; preds = %for.body
; CHECK-NEXT:   store double 0.000000e+00, double* %x, align 8, !tbaa !2
; CHECK-NEXT:   store <3 x double> zeroinitializer, <3 x double>* %"x'", align 8
; CHECK-NEXT:   ret <3 x double> %5

; CHECK: for.body:                                         ; preds = %for.body, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %for.body ], [ 0, %entry ]
; CHECK-NEXT:   %"sum.012'" = phi fast <3 x double> [ zeroinitializer, %entry ], [ %5, %for.body ]
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %0 = trunc i64 %iv to i32
; CHECK-NEXT:   %idxprom = zext i32 %0 to i64
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds <3 x double>, <3 x double>* %"x'", i64 %idxprom
; CHECK-NEXT:   %arrayidx = getelementptr inbounds double, double* %x, i64 %idxprom
; CHECK-NEXT:   %1 = load double, double* %arrayidx, align 8, !tbaa !2
; CHECK-NEXT:   %2 = load <3 x double>, <3 x double>* %"arrayidx'ipg", align 8
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> poison, double %1, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %3 = fmul fast <3 x double> %2, %.splat
; CHECK-NEXT:   %4 = fadd fast <3 x double> %3, %3
; CHECK-NEXT:   %5 = fadd fast <3 x double> %"sum.012'", %4
; CHECK-NEXT:   %inc = add i32 %0, 1
; CHECK-NEXT:   %cmp = icmp ugt i32 %inc, %N
; CHECK-NEXT:   br i1 %cmp, label %for.cond.cleanup, label %for.body
; CHECK-NEXT: }
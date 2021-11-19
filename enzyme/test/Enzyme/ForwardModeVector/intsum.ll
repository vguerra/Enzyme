; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -adce -correlated-propagation -simplifycfg -adce -S | FileCheck %s

%struct.Gradients = type { float, float, float }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(void (float*, float*)*, ...)

define dso_local void @sum(float* %array, float* %ret) #4 {
entry:
  br label %do.body

do.body:                                          ; preds = %do.body, %entry
  %i = phi i64 [ %inc, %do.body ], [ 0, %entry ]
  %intsum = phi i32 [ 0, %entry ], [ %intadd, %do.body ]
  %arrayidx = getelementptr inbounds float, float* %array, i64 %i
  %loaded = load float, float* %arrayidx
  %fltload = bitcast i32 %intsum to float
  %add = fadd float %fltload, %loaded
  %intadd = bitcast float %add to i32
  %inc = add nuw nsw i64 %i, 1
  %cmp = icmp eq i64 %inc, 5
  br i1 %cmp, label %do.end, label %do.body

do.end:                                           ; preds = %do.body
  %lcssa = phi float [ %add, %do.body ]
  store float %lcssa, float* %ret, align 4
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local void @dsum(float* %x, %struct.Gradients* %xp, float* %n, %struct.Gradients* %np) local_unnamed_addr #1 {
entry:
  %0 = tail call %struct.Gradients (void (float*, float*)*, ...) @__enzyme_fwdvectordiff(void (float*, float*)* nonnull @sum, float* %x, %struct.Gradients* %xp, float* %n, %struct.Gradients* %np)
  ret void
}


; CHECK: define internal void @fwdvectordiffesum(float* %array, <3 x float>* %"array'", float* %ret, <3 x float>* %"ret'") {
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %do.body

; CHECK: do.body:                                          ; preds = %do.body, %entry
; CHECK-NEXT:  %iv = phi i64 [ %iv.next, %do.body ], [ 0, %entry ]
; CHECK-NEXT:   %intsum = phi i32 [ 0, %entry ], [ %intadd, %do.body ]
; CHECK-NEXT:   %"intsum'" = phi <3 x i32> [ zeroinitializer, %entry ], [ %3, %do.body ]
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds <3 x float>, <3 x float>* %"array'", i64 %iv
; CHECK-NEXT:   %arrayidx = getelementptr inbounds float, float* %array, i64 %iv
; CHECK-NEXT:   %loaded = load float, float* %arrayidx, align 4
; CHECK-NEXT:   %0 = load <3 x float>, <3 x float>* %"arrayidx'ipg", align 4
; CHECK-NEXT:   %fltload = bitcast i32 %intsum to float
; CHECK-NEXT:   %1 = bitcast <3 x i32> %"intsum'" to <3 x float>
; CHECK-NEXT:   %add = fadd float %fltload, %loaded
; CHECK-NEXT:   %2 = fadd fast <3 x float> %1, %0
; CHECK-NEXT:   %intadd = bitcast float %add to i32
; CHECK-NEXT:   %3 = bitcast <3 x float> %2 to <3 x i32>
; CHECK-NEXT:   %cmp = icmp eq i64 %iv.next, 5
; CHECK-NEXT:   br i1 %cmp, label %do.end, label %do.body

; CHECK: do.end:                                           ; preds = %do.body
; CHECK-NEXT:   store float %add, float* %ret, align 4
; CHECK-NEXT:   store <3 x float> %2, <3 x float>* %"ret'", align 4
; CHECK-NEXT:   ret void
; CHECK-NEXT: }
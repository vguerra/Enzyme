; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -adce -correlated-propagation -simplifycfg -adce -S | FileCheck %s

%struct.Gradients = type { float*, float*, float* }

; Function Attrs: nounwind
declare void @__enzyme_fwdvectordiff(void (float*, float*)*, ...)

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
define dso_local void @dsum(float* %x, %struct.Gradients %xp, float* %n, %struct.Gradients %np) local_unnamed_addr #1 {
entry:
  tail call void (void (float*, float*)*, ...) @__enzyme_fwdvectordiff(void (float*, float*)* nonnull @sum, float* %x, %struct.Gradients %xp, float* %n, %struct.Gradients %np)
  ret void
}


; CHECK: define internal void @fwdvectordiffesum(float* %array, [3 x float*] %"array'", float* %ret, [3 x float*] %"ret'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %do.body

; CHECK: do.body:                                          ; preds = %do.body, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %do.body ], [ 0, %entry ]
; CHECK-NEXT:   %intsum = phi i32 [ 0, %entry ], [ %intadd, %do.body ]
; CHECK-NEXT:   %"intsum'" = phi [3 x i32] [ zeroinitializer, %entry ], [ %27, %do.body ]
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %0 = extractvalue [3 x float*] %"array'", 0
; CHECK-NEXT:   %"arrayidx'ipg" = getelementptr inbounds float, float* %0, i64 %iv
; CHECK-NEXT:   %1 = extractvalue [3 x float*] %"array'", 1
; CHECK-NEXT:   %"arrayidx'ipg1" = getelementptr inbounds float, float* %1, i64 %iv
; CHECK-NEXT:   %2 = extractvalue [3 x float*] %"array'", 2
; CHECK-NEXT:   %"arrayidx'ipg2" = getelementptr inbounds float, float* %2, i64 %iv
; CHECK-NEXT:   %arrayidx = getelementptr inbounds float, float* %array, i64 %iv
; CHECK-NEXT:   %loaded = load float, float* %arrayidx
; CHECK-NEXT:   %3 = load float, float* %"arrayidx'ipg"
; CHECK-NEXT:   %4 = load float, float* %"arrayidx'ipg1"
; CHECK-NEXT:   %5 = load float, float* %"arrayidx'ipg2"
; CHECK-NEXT:   %fltload = bitcast i32 %intsum to float
; CHECK-NEXT:   %6 = extractvalue [3 x i32] %"intsum'", 0
; CHECK-NEXT:   %7 = bitcast i32 %6 to float
; CHECK-NEXT:   %8 = extractvalue [3 x i32] %"intsum'", 1
; CHECK-NEXT:   %9 = bitcast i32 %8 to float
; CHECK-NEXT:   %10 = extractvalue [3 x i32] %"intsum'", 2
; CHECK-NEXT:   %11 = bitcast i32 %10 to float
; CHECK-NEXT:   %add = fadd float %fltload, %loaded
; CHECK-NEXT:   %12 = insertelement <3 x float> undef, float %7, i64 0
; CHECK-NEXT:   %13 = insertelement <3 x float> %12, float %9, i64 1
; CHECK-NEXT:   %14 = insertelement <3 x float> %13, float %11, i64 2
; CHECK-NEXT:   %15 = insertelement <3 x float> undef, float %3, i64 0
; CHECK-NEXT:   %16 = insertelement <3 x float> %15, float %4, i64 1
; CHECK-NEXT:   %17 = insertelement <3 x float> %16, float %5, i64 2
; CHECK-NEXT:   %18 = fadd fast <3 x float> %14, %17
; CHECK-NEXT:   %19 = extractelement <3 x float> %18, i64 0
; CHECK-NEXT:   %20 = extractelement <3 x float> %18, i64 1
; CHECK-NEXT:   %21 = extractelement <3 x float> %18, i64 2
; CHECK-NEXT:   %intadd = bitcast float %add to i32
; CHECK-NEXT:   %22 = bitcast float %19 to i32
; CHECK-NEXT:   %23 = insertvalue [3 x i32] undef, i32 %22, 0
; CHECK-NEXT:   %24 = bitcast float %20 to i32
; CHECK-NEXT:   %25 = insertvalue [3 x i32] %23, i32 %24, 1
; CHECK-NEXT:   %26 = bitcast float %21 to i32
; CHECK-NEXT:   %27 = insertvalue [3 x i32] %25, i32 %26, 2
; CHECK-NEXT:   %cmp = icmp eq i64 %iv.next, 5
; CHECK-NEXT:   br i1 %cmp, label %do.end, label %do.body

; CHECK: do.end:                                           ; preds = %do.body
; CHECK-NEXT:   store float %add, float* %ret, align 4
; CHECK-NEXT:   %28 = extractvalue [3 x float*] %"ret'", 0
; CHECK-NEXT:   store float %19, float* %28, align 4
; CHECK-NEXT:   %29 = extractvalue [3 x float*] %"ret'", 1
; CHECK-NEXT:   store float %20, float* %29, align 4
; CHECK-NEXT:   %30 = extractvalue [3 x float*] %"ret'", 2
; CHECK-NEXT:   store float %21, float* %30, align 4
; CHECK-NEXT:   ret void
; CHECK-NEXT: }
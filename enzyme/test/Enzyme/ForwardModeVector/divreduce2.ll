; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -early-cse-memssa -instsimplify -correlated-propagation -adce -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, double*, %struct.Gradients*, i64, double, %struct.Gradients)

; TODO optimize this style reduction

; Function Attrs: norecurse nounwind readonly uwtable
define double @alldiv(double* nocapture readonly %A, i64 %N, double %start) {
entry:
  br label %loop

loop:                                                ; preds = %9, %5
  %i = phi i64 [ 0, %entry ], [ %next, %body ]
  %reduce = phi double [ %start, %entry ], [ %div, %body ]
  %cmp = icmp ult i64 %i, %N
  br i1 %cmp, label %body, label %end

body:
  %gep = getelementptr inbounds double, double* %A, i64 %i
  %ld = load double, double* %gep, align 8, !tbaa !2
  %div = fdiv double %reduce, %ld
  %next = add nuw nsw i64 %i, 1
  br label %loop

end:                                                ; preds = %9, %3
  ret double %reduce
}

; Function Attrs: nounwind uwtable
define %struct.Gradients @main(double* %A, %struct.Gradients* %dA, i64 %N, double %start) {
  %r = call %struct.Gradients @__enzyme_fwdvectordiff(i8* bitcast (double (double*, i64, double)* @alldiv to i8*), double* %A, %struct.Gradients* %dA, i64 %N, double %start, %struct.Gradients {double 1.0, double 2.0, double 3.0})
  ret %struct.Gradients %r
}

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"Ubuntu clang version 10.0.1-++20200809072545+ef32c611aa2-1~exp1~20200809173142.193"}
!2 = !{!3, !3, i64 0}
!3 = !{!"double", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !4, i64 0}


; CHECK: define internal <3 x double> @fwdvectordiffealldiv(double* nocapture readonly %A, <3 x double>* nocapture %"A'", i64 %N, double %start, <3 x double> %"start'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %loop

; CHECK: loop:                                             ; preds = %body, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %body ], [ 0, %entry ]
; CHECK-NEXT:   %reduce = phi double [ %start, %entry ], [ %div, %body ]
; CHECK-NEXT:   %"reduce'" = phi fast <3 x double> [ %"start'", %entry ], [ %5, %body ]
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %cmp = icmp ne i64 %iv, %N
; CHECK-NEXT:   br i1 %cmp, label %body, label %end

; CHECK: body:                                             ; preds = %loop
; CHECK-NEXT:   %"gep'ipg" = getelementptr inbounds <3 x double>, <3 x double>* %"A'", i64 %iv
; CHECK-NEXT:   %gep = getelementptr inbounds double, double* %A, i64 %iv
; CHECK-NEXT:   %ld = load double, double* %gep, align 8, !tbaa !2
; CHECK-NEXT:   %0 = load <3 x double>, <3 x double>* %"gep'ipg", align 8
; CHECK-NEXT:   %div = fdiv double %reduce, %ld
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> poison, double %ld, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %1 = fmul fast <3 x double> %"reduce'", %.splat
; CHECK-NEXT:   %.splatinsert1 = insertelement <3 x double> poison, double %reduce, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <3 x double> %.splatinsert1, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %2 = fmul fast <3 x double> %.splat2, %0
; CHECK-NEXT:   %3 = fsub fast <3 x double> %1, %2
; CHECK-NEXT:   %4 = fmul fast <3 x double> %.splat, %.splat
; CHECK-NEXT:   %5 = fdiv fast <3 x double> %3, %4
; CHECK-NEXT:   br label %loop

; CHECK: end:                                              ; preds = %loop
; CHECK-NEXT:   ret <3 x double> %"reduce'"
; CHECK-NEXT: }
; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -early-cse-memssa -instsimplify -correlated-propagation -adce -S | FileCheck %s

%struct.InGradients = type { double*, double*, double* }
%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, double*, %struct.InGradients, i64, double, %struct.Gradients)
; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff2(i8*, double*, %struct.InGradients, i64)


; Function Attrs: norecurse nounwind readonly uwtable
define double @alldiv(double* nocapture readonly %A, i64 %N, double %start) {
entry:
  br label %loop

loop:                                                ; preds = %9, %5
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %reduce = phi double [ %start, %entry ], [ %div, %loop ]
  %gep = getelementptr inbounds double, double* %A, i64 %i
  %ld = load double, double* %gep, align 8, !tbaa !2
  %div = fdiv double %reduce, %ld
  %next = add nuw nsw i64 %i, 1
  %cmp = icmp eq i64 %next, %N
  br i1 %cmp, label %end, label %loop

end:                                                ; preds = %9, %3
  ret double %div
}

define double @alldiv2(double* nocapture readonly %A, i64 %N) {
entry:
  br label %loop

loop:                                                ; preds = %9, %5
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %reduce = phi double [ 2.000000e+00, %entry ], [ %div, %loop ]
  %gep = getelementptr inbounds double, double* %A, i64 %i
  %ld = load double, double* %gep, align 8, !tbaa !2
  %div = fdiv double %reduce, %ld
  %next = add nuw nsw i64 %i, 1
  %cmp = icmp eq i64 %next, %N
  br i1 %cmp, label %end, label %loop

end:                                                ; preds = %9, %3
  ret double %div
}

; Function Attrs: nounwind uwtable
define %struct.Gradients @main(double* %A, %struct.InGradients %dA, i64 %N, double %start) {
  %r = call %struct.Gradients @__enzyme_fwdvectordiff(i8* bitcast (double (double*, i64, double)* @alldiv to i8*), double* %A, %struct.InGradients %dA, i64 %N, double %start, %struct.Gradients {double 1.0, double 2.0, double 3.0})
  %r2 = call %struct.Gradients @__enzyme_fwdvectordiff2(i8* bitcast (double (double*, i64)* @alldiv2 to i8*), double* %A, %struct.InGradients %dA, i64 %N)
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


; CHECK: define internal [3 x double] @fwdvectordiffealldiv(double* nocapture readonly %A, [3 x double*] %"A'", i64 %N, double %start, [3 x double] %"start'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %loop

; CHECK: loop:                                             ; preds = %loop, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %loop ], [ 0, %entry ]
; CHECK-NEXT:   %reduce = phi double [ %start, %entry ], [ %div, %loop ]
; CHECK-NEXT:   %"reduce'" = phi {{(fast )?}}[3 x double] [ %"start'", %entry ], [ %25, %loop ]
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %0 = extractvalue [3 x double*] %"A'", 0
; CHECK-NEXT:   %"gep'ipg" = getelementptr inbounds double, double* %0, i64 %iv
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"A'", 1
; CHECK-NEXT:   %"gep'ipg1" = getelementptr inbounds double, double* %1, i64 %iv
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"A'", 2
; CHECK-NEXT:   %"gep'ipg2" = getelementptr inbounds double, double* %2, i64 %iv
; CHECK-NEXT:   %gep = getelementptr inbounds double, double* %A, i64 %iv
; CHECK-NEXT:   %ld = load double, double* %gep, align 8, !tbaa !2
; CHECK-NEXT:   %3 = load double, double* %"gep'ipg", align 8
; CHECK-NEXT:   %4 = load double, double* %"gep'ipg1", align 8
; CHECK-NEXT:   %5 = load double, double* %"gep'ipg2", align 8
; CHECK-NEXT:   %div = fdiv double %reduce, %ld
; CHECK-NEXT:   %6 = extractvalue [3 x double] %"reduce'", 0
; CHECK-NEXT:   %7 = insertelement <3 x double> undef, double %6, i64 0
; CHECK-NEXT:   %8 = extractvalue [3 x double] %"reduce'", 1
; CHECK-NEXT:   %9 = insertelement <3 x double> %7, double %8, i64 1
; CHECK-NEXT:   %10 = extractvalue [3 x double] %"reduce'", 2
; CHECK-NEXT:   %11 = insertelement <3 x double> %9, double %10, i64 2
; CHECK-NEXT:   %12 = insertelement <3 x double> undef, double %3, i64 0
; CHECK-NEXT:   %13 = insertelement <3 x double> %12, double %4, i64 1
; CHECK-NEXT:   %14 = insertelement <3 x double> %13, double %5, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{poison|undef}}, double %ld, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %15 = fmul fast <3 x double> %11, %.splat
; CHECK-NEXT:   %.splatinsert3 = insertelement <3 x double> {{poison|undef}}, double %reduce, i32 0
; CHECK-NEXT:   %.splat4 = shufflevector <3 x double> %.splatinsert3, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %16 = fmul fast <3 x double> %.splat4, %14
; CHECK-NEXT:   %17 = fsub fast <3 x double> %15, %16
; CHECK-NEXT:   %18 = fmul fast <3 x double> %.splat, %.splat
; CHECK-NEXT:   %19 = fdiv fast <3 x double> %17, %18
; CHECK-NEXT:   %20 = extractelement <3 x double> %19, i64 0
; CHECK-NEXT:   %21 = insertvalue [3 x double] undef, double %20, 0
; CHECK-NEXT:   %22 = extractelement <3 x double> %19, i64 1
; CHECK-NEXT:   %23 = insertvalue [3 x double] %21, double %22, 1
; CHECK-NEXT:   %24 = extractelement <3 x double> %19, i64 2
; CHECK-NEXT:   %25 = insertvalue [3 x double] %23, double %24, 2
; CHECK-NEXT:   %cmp = icmp eq i64 %iv.next, %N
; CHECK-NEXT:   br i1 %cmp, label %end, label %loop

; CHECK: end:                                              ; preds = %loop
; CHECK-NEXT:   ret [3 x double] %25
; CHECK-NEXT: }

; CHECK: define internal [3 x double] @fwdvectordiffealldiv2(double* nocapture readonly %A, [3 x double*] %"A'", i64 %N)
; CHECK-NEXT: entry:
; CHECK-NEXT:   br label %loop

; CHECK: loop:                                             ; preds = %loop, %entry
; CHECK-NEXT:   %iv = phi i64 [ %iv.next, %loop ], [ 0, %entry ]
; CHECK-NEXT:   %reduce = phi double [ 2.000000e+00, %entry ], [ %div, %loop ]
; CHECK-NEXT:   %"reduce'" = phi {{(fast )?}}[3 x double] [ zeroinitializer, %entry ], [ %25, %loop ]
; CHECK-NEXT:   %iv.next = add nuw nsw i64 %iv, 1
; CHECK-NEXT:   %0 = extractvalue [3 x double*] %"A'", 0
; CHECK-NEXT:   %"gep'ipg" = getelementptr inbounds double, double* %0, i64 %iv
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"A'", 1
; CHECK-NEXT:   %"gep'ipg1" = getelementptr inbounds double, double* %1, i64 %iv
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"A'", 2
; CHECK-NEXT:   %"gep'ipg2" = getelementptr inbounds double, double* %2, i64 %iv
; CHECK-NEXT:   %gep = getelementptr inbounds double, double* %A, i64 %iv
; CHECK-NEXT:   %ld = load double, double* %gep, align 8, !tbaa !2
; CHECK-NEXT:   %3 = load double, double* %"gep'ipg", align 8
; CHECK-NEXT:   %4 = load double, double* %"gep'ipg1", align 8
; CHECK-NEXT:   %5 = load double, double* %"gep'ipg2", align 8
; CHECK-NEXT:   %div = fdiv double %reduce, %ld
; CHECK-NEXT:   %6 = extractvalue [3 x double] %"reduce'", 0
; CHECK-NEXT:   %7 = insertelement <3 x double> undef, double %6, i64 0
; CHECK-NEXT:   %8 = extractvalue [3 x double] %"reduce'", 1
; CHECK-NEXT:   %9 = insertelement <3 x double> %7, double %8, i64 1
; CHECK-NEXT:   %10 = extractvalue [3 x double] %"reduce'", 2
; CHECK-NEXT:   %11 = insertelement <3 x double> %9, double %10, i64 2
; CHECK-NEXT:   %12 = insertelement <3 x double> undef, double %3, i64 0
; CHECK-NEXT:   %13 = insertelement <3 x double> %12, double %4, i64 1
; CHECK-NEXT:   %14 = insertelement <3 x double> %13, double %5, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{poison|undef}}, double %ld, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %15 = fmul fast <3 x double> %11, %.splat
; CHECK-NEXT:   %.splatinsert3 = insertelement <3 x double> {{poison|undef}}, double %reduce, i32 0
; CHECK-NEXT:   %.splat4 = shufflevector <3 x double> %.splatinsert3, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %16 = fmul fast <3 x double> %.splat4, %14
; CHECK-NEXT:   %17 = fsub fast <3 x double> %15, %16
; CHECK-NEXT:   %18 = fmul fast <3 x double> %.splat, %.splat
; CHECK-NEXT:   %19 = fdiv fast <3 x double> %17, %18
; CHECK-NEXT:   %20 = extractelement <3 x double> %19, i64 0
; CHECK-NEXT:   %21 = insertvalue [3 x double] undef, double %20, 0
; CHECK-NEXT:   %22 = extractelement <3 x double> %19, i64 1
; CHECK-NEXT:   %23 = insertvalue [3 x double] %21, double %22, 1
; CHECK-NEXT:   %24 = extractelement <3 x double> %19, i64 2
; CHECK-NEXT:   %25 = insertvalue [3 x double] %23, double %24, 2
; CHECK-NEXT:   %cmp = icmp eq i64 %iv.next, %N
; CHECK-NEXT:   br i1 %cmp, label %end, label %loop

; CHECK: end:                                              ; preds = %loop
; CHECK-NEXT:   ret [3 x double] %25
; CHECK-NEXT: }
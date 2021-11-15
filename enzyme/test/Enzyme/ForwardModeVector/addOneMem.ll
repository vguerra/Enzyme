; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -inline -mem2reg -instsimplify -gvn -dse -dse -S | FileCheck %s

; typedef struct {
;     double x1,x2,x3;
; } Gradients;

; extern void __enzyme_fwdvectordiff(void (double*), ...);

; void addOneMem(double *x) {
;     *x += 1;
; }

; void test_derivative(double *x, Gradients *xp) {
;     return __enzyme_fwdvectordiff(addOneMem, x, xp);
; }


%struct.Gradients = type { double, double, double }

define void @addOneMem(double* nocapture %x) {
entry:
  %0 = load double, double* %x, align 8
  %add = fadd double %0, 1.000000e+00
  store double %add, double* %x, align 8
  ret void
}

define void @test_derivative(double* %x, %struct.Gradients* %xp) {
entry:
  call void (void (double*)*, ...) @__enzyme_fwdvectordiff(void (double*)* nonnull @addOneMem, double* %x, %struct.Gradients* %xp)
  ret void
}

declare void @__enzyme_fwdvectordiff(void (double*)*, ...)


; CHECK: define {{(dso_local )?}}void @test_derivative(double* %x, %struct.Gradients* %xp)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %xp, i32 0, i32 0
; CHECK-NEXT:   %1 = load double, double* %0, align 8
; CHECK-NEXT:   %2 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %xp, i32 0, i32 1
; CHECK-NEXT:   %3 = load double, double* %2, align 8
; CHECK-NEXT:   %4 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %xp, i32 0, i32 2
; CHECK-NEXT:   %5 = load double, double* %4, align 8
; CHECK-NEXT:   %6 = load double, double* %x, align 8
; CHECK-NEXT:   %add.i = fadd double %6, 1.000000e+00
; CHECK-NEXT:   store double %add.i, double* %x, align 8
; CHECK-NEXT:   store double %1, double* %0, align 8
; CHECK-NEXT:   store double %3, double* %2, align 8
; CHECK-NEXT:   store double %5, double* %4, align 8
; CHECK-NEXT:   ret void
; CHECK-NEXT: }
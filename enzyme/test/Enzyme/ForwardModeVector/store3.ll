; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -adce -correlated-propagation -simplifycfg -gvn -dse -S | FileCheck %s

%struct.Gradients1 = type { double*, double*, double* }
%struct.Gradients2 = type { double, double, double }

; Function Attrs: noinline norecurse nounwind uwtable
define dso_local double @f(double* noalias nocapture %out, double %x) #0 {
entry:
  store double %x, double* %out, align 8
  store double 0.000000e+00, double* %out, align 8
  %res = load double, double* %out
  ret double %res
}

; Function Attrs: noinline nounwind uwtable
define dso_local %struct.Gradients2 @dsumsquare(double* %x, %struct.Gradients1 %xp, double %inp, %struct.Gradients2 %in2) local_unnamed_addr #1 {
entry:
  %call = tail call %struct.Gradients2 @__enzyme_fwdvectordiff(i8* bitcast (double (double*, double)* @f to i8*), double* %x, %struct.Gradients1 %xp, double %inp, %struct.Gradients2 %in2)
  ret %struct.Gradients2 %call
}

declare dso_local %struct.Gradients2 @__enzyme_fwdvectordiff(i8*, double*, %struct.Gradients1, double, %struct.Gradients2) local_unnamed_addr

attributes #0 = { noinline norecurse nounwind uwtable }
attributes #1 = { noinline nounwind uwtable }


; CHECK: define internal [3 x double] @fwdvectordiffef(double* noalias nocapture %out, [3 x double*] %"out'", double %x, [3 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [3 x double*] %"out'", 0
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"out'", 1
; CHECK-NEXT:   %2 = extractvalue [3 x double*] %"out'", 2
; CHECK-NEXT:   store double 0.000000e+00, double* %out, align 8
; CHECK-NEXT:   store double 0.000000e+00, double* %0, align 8
; CHECK-NEXT:   store double 0.000000e+00, double* %1, align 8
; CHECK-NEXT:   store double 0.000000e+00, double* %2, align 8
; CHECK-NEXT:   %3 = load double, double* %0
; CHECK-NEXT:   %4 = insertvalue [3 x double] undef, double %3, 0
; CHECK-NEXT:   %5 = load double, double* %1
; CHECK-NEXT:   %6 = insertvalue [3 x double] %4, double %5, 1
; CHECK-NEXT:   %7 = insertvalue [3 x double] %6, double 0.000000e+00, 2
; CHECK-NEXT:   ret [3 x double] %7
; CHECK-NEXT: }
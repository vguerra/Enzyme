; RUN: if [ %llvmver -ge 10 ]; then %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s; fi

%struct.Gradients = type { double, double, double }

declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)


define dso_local double @fneg(double %x) {
entry:
  %fneg = fneg double %x
  ret double %fneg
}

define dso_local void @fnegd(double %x) {
entry:
  %0 = call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @fneg, double %x, [3 x double] [double 1.0, double 2.5, double 3.0])
  ret void
}


; CHECK: define internal [3 x double] @fwdvectordiffefneg(double %x, [3 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [3 x double] %"x'", 0
; CHECK-NEXT:   %1 = insertelement <3 x double> undef, double %0, i64 0
; CHECK-NEXT:   %2 = extractvalue [3 x double] %"x'", 1
; CHECK-NEXT:   %3 = insertelement <3 x double> %1, double %2, i64 1
; CHECK-NEXT:   %4 = extractvalue [3 x double] %"x'", 2
; CHECK-NEXT:   %5 = insertelement <3 x double> %3, double %4, i64 2
; CHECK-NEXT:   %6 = fneg fast <3 x double> %5
; CHECK-NEXT:   %7 = extractelement <3 x double> %6, i64 0
; CHECK-NEXT:   %8 = insertvalue [3 x double] undef, double %7, 0
; CHECK-NEXT:   %9 = extractelement <3 x double> %6, i64 1
; CHECK-NEXT:   %10 = insertvalue [3 x double] %8, double %9, 1
; CHECK-NEXT:   %11 = extractelement <3 x double> %6, i64 2
; CHECK-NEXT:   %12 = insertvalue [3 x double] %10, double %11, 2
; CHECK-NEXT:   ret [3 x double] %12
; CHECK-NEXT: }
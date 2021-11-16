; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

; typedef struct {
;     double x1,x2,x3;
; } Gradients;

; extern Gradients __enzyme_fwdvectordiff(double (double), ...);

; __attribute__((noinline))
; double add2(double x) {
;     return 2 + x;
; }

; __attribute__((noinline))
; double add4(double x) {
;     return add2(x) + 2;
; }

; Gradients dadd4(double x) {
;     return __enzyme_fwdvectordiff(add4, x, (Gradients){1.0,2.0,3.0});
; }

%struct.Gradients = type { double, double, double }

define double @_Z4add2d(double %x) {
entry:
  %add = fadd double %x, 2.000000e+00
  ret double %add
}

define double @_Z4add4d(double %x) {
entry:
  %call = call double @_Z4add2d(double %x)
  %add = fadd double %call, 2.000000e+00
  ret double %add
}

define %struct.Gradients @_Z5dadd4d(double %x) {
entry:
  %call = call %struct.Gradients (double (double)*, ...) @_Z22__enzyme_fwdvectordiffPFddEz(double (double)* nonnull @_Z4add4d, double %x, [3 x double] [double 1.000000e+00, double 2.000000e+00, double 3.000000e+00])
  ret %struct.Gradients %call
}

declare %struct.Gradients @_Z22__enzyme_fwdvectordiffPFddEz(double (double)*, ...)

; CHECK: define internal {{(dso_local )?}}<3 x double> @fwdvectordiffe_Z4add4d(double %x, <3 x double> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = call fast <3 x double> @fwdvectordiffe_Z4add2d(double %x, <3 x double> %"x'")
; CHECK-NEXT:   ret <3 x double> %0
; CHECK-NEXT: }

; CHECK: define internal {{(dso_local )?}}<3 x double> @fwdvectordiffe_Z4add2d(double %x, <3 x double> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   ret <3 x double> %"x'"
; CHECK-NEXT: }
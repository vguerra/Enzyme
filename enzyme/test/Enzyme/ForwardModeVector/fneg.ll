; RUN: if [ %llvmver -ge 10 ]; then %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s; fi

;  typedef struct {
;      double x1,x2,x3;
;  } Gradients;

;  extern Gradients __enzyme_fwdvectordiff(double (double), ...);

;  double fneg(double x) {
;      return -x; 
; }
 
; Gradients dfneg(double x) {
;      return __enzyme_fwdvectordiff(fneg, x, (Gradients){1.0, 2.0, 3.0});
; }

%struct.Gradients = type { double, double, double }

define dso_local double @fneg(double %x) {
entry:
  %fneg = fneg double %x
  ret double %fneg
}

define dso_local void @fnegd(%struct.Gradients* noalias sret(%struct.Gradients) align 8 %agg.result, double %x) {
entry:
  %agg.tmp = alloca %struct.Gradients, align 8
  %x1 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %agg.tmp, i64 0, i32 0
  store double 1.000000e+00, double* %x1, align 8
  %x2 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %agg.tmp, i64 0, i32 1
  store double 2.000000e+00, double* %x2, align 8
  %x3 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %agg.tmp, i64 0, i32 2
  store double 3.000000e+00, double* %x3, align 8
  call void (%struct.Gradients*, double (double)*, ...) @__enzyme_fwdvectordiff(%struct.Gradients* sret(%struct.Gradients) align 8 %agg.result, double (double)* nonnull @fneg, double %x, %struct.Gradients* nonnull byval(%struct.Gradients) align 8 %agg.tmp)
  ret void
}

declare dso_local void @__enzyme_fwdvectordiff(%struct.Gradients* sret(%struct.Gradients) align 8, double (double)*, ...)


; CHECK: define internal <3 x double> @fwdvectordiffefneg(double %x, <3 x double> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = fneg fast <3 x double> %"x'"
; CHECK-NEXT:   ret <3 x double> %0
; CHECK-NEXT: }
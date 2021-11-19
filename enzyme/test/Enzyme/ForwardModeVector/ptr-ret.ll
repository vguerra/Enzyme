; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(...)

define dso_local noalias nonnull double* @_Z6toHeapd(double %x) {
entry:
  %call = call noalias nonnull dereferenceable(8) i8* @_Znwm(i64 8)
  %0 = bitcast i8* %call to double*
  store double %x, double* %0, align 8
  ret double* %0
}

declare dso_local nonnull i8* @_Znwm(i64)

define dso_local double @_Z6squared(double %x) {
entry:
  %call = call double* @_Z6toHeapd(double %x)
  %0 = load double, double* %call, align 8
  %mul = fmul double %0, %x
  ret double %mul
}

define dso_local %struct.Gradients @_Z7dsquared(double %x) {
entry:
  %call = call %struct.Gradients (...) @__enzyme_fwdvectordiff(i8* bitcast (double (double)* @_Z6squared to i8*), double %x, [3 x double] [double 1.0, double 2.0, double 3.0])
  ret %struct.Gradients %call
}
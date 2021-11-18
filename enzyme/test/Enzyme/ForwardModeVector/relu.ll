; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -inline -early-cse -instcombine -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double)*, ...)


define dso_local double @f(double %x) #1 {
entry:
  ret double %x
}

define dso_local double @relu(double %x) {
entry:
  %cmp = fcmp fast ogt double %x, 0.000000e+00
  br i1 %cmp, label %cond.true, label %cond.end

cond.true:                                        ; preds = %entry
  %call = tail call fast double @f(double %x)
  br label %cond.end

cond.end:                                         ; preds = %entry, %cond.true
  %cond = phi double [ %call, %cond.true ], [ 0.000000e+00, %entry ]
  ret double %cond
}

define dso_local %struct.Gradients @drelu(double %x) {
entry:
  %0 = tail call %struct.Gradients (double (double)*, ...) @__enzyme_fwdvectordiff(double (double)* nonnull @relu, double %x, [2 x double] [double 0.0, double 1.0])
  ret %struct.Gradients %0
}

declare double @__enzyme_fwddiff(double (double)*, ...) #0

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone noinline }


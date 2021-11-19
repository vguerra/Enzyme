; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -early-cse -simplifycfg -S | FileCheck %s

%struct.Gradients = type { float, float, float }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff.f64(...)

; Function Attrs: noinline nounwind uwtable
define dso_local float @man_max(float* %a, float* %b) #0 {
entry:
  %0 = load float, float* %a, align 4
  %1 = load float, float* %b, align 4
  %cmp = fcmp ogt float %0, %1
  %a.b = select i1 %cmp, float* %a, float* %b
  %retval.0 = load float, float* %a.b, align 4
  ret float %retval.0
}

define void @dman_max(float* %a, %struct.Gradients* %da, float* %b, %struct.Gradients* %db) {
entry:
  call %struct.Gradients (...) @__enzyme_fwdvectordiff.f64(float (float*, float*)* @man_max, float* %a, %struct.Gradients* %da, float* %b, %struct.Gradients* %db)
  ret void
}

attributes #0 = { noinline }


; CHECK: define internal <3 x float> @fwdvectordiffeman_max(float* %a, <3 x float>* %"a'", float* %b, <3 x float>* %"b'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = load float, float* %a, align 4
; CHECK-NEXT:   %1 = load float, float* %b, align 4
; CHECK-NEXT:   %cmp = fcmp ogt float %0, %1
; CHECK-NEXT:   %"a.b'ipse" = select i1 %cmp, <3 x float>* %"a'", <3 x float>* %"b'"
; CHECK-NEXT:   %2 = load <3 x float>, <3 x float>* %"a.b'ipse", align 4
; CHECK-NEXT:   ret <3 x float> %2
; CHECK-NEXT: }
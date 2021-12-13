; RUN: if [ %llvmver -ge 12 ]; then %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s; fi

%struct.InGradients1 = type { float, float }
%struct.InGradients2 = type {  float, float, float, float, float, float, float, float }
%struct.Gradients = type { float, float }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(float (float, <4 x float>)*, ...)

define float @tester(float %start_value, <4 x float> %input) {
entry:
  %ord = call float @llvm.vector.reduce.fadd.v4f32(float %start_value, <4 x float> %input)
  ret float %ord
}

define %struct.Gradients @test_derivative(float %start_value, <4 x float> %input) {
entry:
  %0 = tail call %struct.Gradients (float (float, <4 x float>)*, ...) @__enzyme_fwdvectordiff(float (float, <4 x float>)* nonnull @tester, float %start_value, %struct.InGradients1 {float 1.0, float 2.0}, <4 x float> %input, %struct.InGradients2 { float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0 })
  ret %struct.Gradients %0
}

declare float @llvm.vector.reduce.fadd.v4f32(float, <4 x float>)


; CHECK: define internal [2 x float] @fwdvectordiffetester(float %start_value, [2 x float] %"start_value'", <4 x float> %input, [2 x <4 x float>] %"input'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [2 x float] %"start_value'", 0
; CHECK-NEXT:   %1 = extractvalue [2 x <4 x float>] %"input'", 0
; CHECK-NEXT:   %2 = call fast float @llvm.vector.reduce.fadd.v4f32(float %0, <4 x float> %1)
; CHECK-NEXT:   %3 = insertvalue [2 x float] undef, float %2, 0
; CHECK-NEXT:   %4 = extractvalue [2 x float] %"start_value'", 1
; CHECK-NEXT:   %5 = extractvalue [2 x <4 x float>] %"input'", 1
; CHECK-NEXT:   %6 = call fast float @llvm.vector.reduce.fadd.v4f32(float %4, <4 x float> %5)
; CHECK-NEXT:   %7 = insertvalue [2 x float] %3, float %6, 1
; CHECK-NEXT:   ret [2 x float] %7
; CHECK-NEXT: }
; RUN: if [ %llvmver -ge 9 ] && [ %llvmver -le 11 ]; then %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s; fi

%struct.Gradients = type { float, float, float, float, float, float, float, float }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(float (float, <4 x float>)*, ...)

define float @tester(float %start_value, <4 x float> %input) {
entry:
  %ord = call float @llvm.experimental.vector.reduce.v2.fadd.f32.v4f32(float %start_value, <4 x float> %input)
  ret float %ord
}

define %struct.Gradients @test_derivative(float %start_value, <4 x float> %input) {
entry:
  %0 = tail call %struct.Gradients (float (float, <4 x float>)*, ...) @__enzyme_fwdvectordiff(float (float, <4 x float>)* nonnull @tester, float %start_value, [2 x float] [float 1.0, float 2.0], <4 x float> %input, [8 x float] [float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0, float 1.0])
  ret %struct.Gradients %0
}

declare float @llvm.experimental.vector.reduce.v2.fadd.f32.v4f32(float, <4 x float>)

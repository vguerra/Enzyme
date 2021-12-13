; RUN: if [ %llvmver -lt 12 ]; then %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -simplifycfg -early-cse -S | FileCheck %s ; fi


; #include <stdio.h>
; #include <array>

; using namespace std;

; extern array<double,3> __enzyme_fwddiff(void*, ...);

; array<double,3> square(double x) {
;     return {x * x, x * x * x, x};
; }
; array<double,3> dsquare(double x) {
;     // This returns the derivative of square or 2 * x
;     return __enzyme_fwddiff((void*)square, x, 1.0);
; }
; int main() {
;     printf("%f \n", dsquare(3)[0]);
; }


%struct.InGradients = type { double, double, double }
%"struct.std::array" = type { [3 x double] }
%struct.OutGradients = type { %"struct.std::array", %"struct.std::array", %"struct.std::array" }

$_ZNSt5arrayIdLm3EEixEm = comdat any

$_ZNSt14__array_traitsIdLm3EE6_S_refERA3_Kdm = comdat any

@__const._Z7dsquared.dx = private unnamed_addr constant %struct.InGradients { double 1.000000e+00, double 2.000000e+00, double 3.000000e+00 }, align 8
@.str = private unnamed_addr constant [5 x i8] c"%f \0A\00", align 1

define dso_local void @_Z6squared(%"struct.std::array"* noalias nocapture sret align 8 %agg.result, double %x) {
entry:
  %arrayinit.begin = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %agg.result, i64 0, i32 0, i64 0
  %mul = fmul double %x, %x
  store double %mul, double* %arrayinit.begin, align 8
  %arrayinit.element = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %agg.result, i64 0, i32 0, i64 1
  %mul2 = fmul double %mul, %x
  store double %mul2, double* %arrayinit.element, align 8
  %arrayinit.element3 = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %agg.result, i64 0, i32 0, i64 2
  store double %x, double* %arrayinit.element3, align 8
  ret void
}

define dso_local void @_Z7dsquared(%struct.OutGradients* noalias sret align 8 %agg.result, double %x) {
entry:
  call void (%struct.OutGradients*, i8*, ...) @_Z22__enzyme_fwdvectordiffPvz(%struct.OutGradients* sret align 8 %agg.result, i8* bitcast (void (%"struct.std::array"*, double)* @_Z6squared to i8*), double %x, %struct.InGradients* nonnull byval align 8 @__const._Z7dsquared.dx)
  ret void
}

declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture)

declare dso_local void @_Z22__enzyme_fwdvectordiffPvz(%struct.OutGradients* sret align 8, i8*, ...)

declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture)

define dso_local i32 @main() {
entry:
  %ref.tmp = alloca %struct.OutGradients, align 8
  %0 = bitcast %struct.OutGradients* %ref.tmp to i8*
  call void @llvm.lifetime.start.p0i8(i64 72, i8* nonnull %0) #7
  call void @_Z7dsquared(%struct.OutGradients* nonnull sret align 8 %ref.tmp, double 3.000000e+00)
  %dx1 = getelementptr inbounds %struct.OutGradients, %struct.OutGradients* %ref.tmp, i64 0, i32 0
  %call = call nonnull align 8 dereferenceable(8) double* @_ZNSt5arrayIdLm3EEixEm(%"struct.std::array"* nonnull dereferenceable(24) %dx1, i64 0) #7
  %1 = load double, double* %call, align 8
  %call1 = call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([5 x i8], [5 x i8]* @.str, i64 0, i64 0), double %1)
  call void @llvm.lifetime.end.p0i8(i64 72, i8* nonnull %0) #7
  ret i32 0
}

declare dso_local i32 @printf(i8* nocapture readonly, ...)

define linkonce_odr dso_local nonnull align 8 dereferenceable(8) double* @_ZNSt5arrayIdLm3EEixEm(%"struct.std::array"* nonnull dereferenceable(24) %this, i64 %__n) local_unnamed_addr #6 comdat align 2 {
entry:
  %_M_elems = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %this, i64 0, i32 0
  %call = call nonnull align 8 dereferenceable(8) double* @_ZNSt14__array_traitsIdLm3EE6_S_refERA3_Kdm([3 x double]* nonnull align 8 dereferenceable(24) %_M_elems, i64 %__n) #7
  ret double* %call
}

define linkonce_odr dso_local nonnull align 8 dereferenceable(8) double* @_ZNSt14__array_traitsIdLm3EE6_S_refERA3_Kdm([3 x double]* nonnull align 8 dereferenceable(24) %__t, i64 %__n) local_unnamed_addr #6 comdat align 2 {
entry:
  %arrayidx = getelementptr inbounds [3 x double], [3 x double]* %__t, i64 0, i64 %__n
  ret double* %arrayidx
}

; CHECK: define internal void @fwdvectordiffe_Z6squared(%"struct.std::array"* noalias nocapture align 8 %agg.result, [3 x %"struct.std::array"*] %"agg.result'", double %x, [3 x double] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = extractvalue [3 x %"struct.std::array"*] %"agg.result'", 0
; CHECK-NEXT:   %"arrayinit.begin'ipg" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %0, i64 0, i32 0, i64 0
; CHECK-NEXT:   %1 = insertvalue [3 x double*] undef, double* %"arrayinit.begin'ipg", 0
; CHECK-NEXT:   %2 = extractvalue [3 x %"struct.std::array"*] %"agg.result'", 1
; CHECK-NEXT:   %"arrayinit.begin'ipg3" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %2, i64 0, i32 0, i64 0
; CHECK-NEXT:   %3 = insertvalue [3 x double*] %1, double* %"arrayinit.begin'ipg3", 1
; CHECK-NEXT:   %4 = extractvalue [3 x %"struct.std::array"*] %"agg.result'", 2
; CHECK-NEXT:   %"arrayinit.begin'ipg4" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %4, i64 0, i32 0, i64 0
; CHECK-NEXT:   %5 = insertvalue [3 x double*] %3, double* %"arrayinit.begin'ipg4", 2
; CHECK-NEXT:   %arrayinit.begin = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %agg.result, i64 0, i32 0, i64 0
; CHECK-NEXT:   %mul = fmul double %x, %x
; CHECK-NEXT:   %6 = extractvalue [3 x double] %"x'", 0
; CHECK-NEXT:   %7 = insertelement <3 x double> undef, double %6, i64 0
; CHECK-NEXT:   %8 = extractvalue [3 x double] %"x'", 1
; CHECK-NEXT:   %9 = insertelement <3 x double> %7, double %8, i64 1
; CHECK-NEXT:   %10 = extractvalue [3 x double] %"x'", 2
; CHECK-NEXT:   %11 = insertelement <3 x double> %9, double %10, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{poison|undef}}, double %x, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %12 = fmul fast <3 x double> %11, %.splat
; CHECK-NEXT:   %13 = fadd fast <3 x double> %12, %12
; CHECK-NEXT:   %14 = extractelement <3 x double> %13, i64 0
; CHECK-NEXT:   %15 = insertvalue [3 x double] undef, double %14, 0
; CHECK-NEXT:   %16 = extractelement <3 x double> %13, i64 1
; CHECK-NEXT:   %17 = insertvalue [3 x double] %15, double %16, 1
; CHECK-NEXT:   %18 = extractelement <3 x double> %13, i64 2
; CHECK-NEXT:   %19 = insertvalue [3 x double] %17, double %18, 2
; CHECK-NEXT:   store double %mul, double* %arrayinit.begin, align 8
; CHECK-NEXT:   store double %14, double* %"arrayinit.begin'ipg", align 8
; CHECK-NEXT:   store double %16, double* %"arrayinit.begin'ipg3", align 8
; CHECK-NEXT:   store double %18, double* %"arrayinit.begin'ipg4", align 8
; CHECK-NEXT:   %"arrayinit.element'ipg" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %0, i64 0, i32 0, i64 1
; CHECK-NEXT:   %20 = insertvalue [3 x double*] undef, double* %"arrayinit.element'ipg", 0
; CHECK-NEXT:   %"arrayinit.element'ipg9" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %2, i64 0, i32 0, i64 1
; CHECK-NEXT:   %21 = insertvalue [3 x double*] %20, double* %"arrayinit.element'ipg9", 1
; CHECK-NEXT:   %"arrayinit.element'ipg10" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %4, i64 0, i32 0, i64 1
; CHECK-NEXT:   %22 = insertvalue [3 x double*] %21, double* %"arrayinit.element'ipg10", 2
; CHECK-NEXT:   %arrayinit.element = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %agg.result, i64 0, i32 0, i64 1
; CHECK-NEXT:   %mul2 = fmul double %mul, %x
; CHECK-NEXT:   %23 = insertelement <3 x double> undef, double %14, i64 0
; CHECK-NEXT:   %24 = insertelement <3 x double> %23, double %16, i64 1
; CHECK-NEXT:   %25 = insertelement <3 x double> %24, double %18, i64 2
; CHECK-NEXT:   %26 = fmul fast <3 x double> %25, %.splat
; CHECK-NEXT:   %.splatinsert7 = insertelement <3 x double> {{poison|undef}}, double %mul, i32 0
; CHECK-NEXT:   %.splat8 = shufflevector <3 x double> %.splatinsert7, <3 x double> {{poison|undef}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %27 = fmul fast <3 x double> %11, %.splat8
; CHECK-NEXT:   %28 = fadd fast <3 x double> %26, %27
; CHECK-NEXT:   %29 = extractelement <3 x double> %28, i64 0
; CHECK-NEXT:   %30 = insertvalue [3 x double] undef, double %29, 0
; CHECK-NEXT:   %31 = extractelement <3 x double> %28, i64 1
; CHECK-NEXT:   %32 = insertvalue [3 x double] %30, double %31, 1
; CHECK-NEXT:   %33 = extractelement <3 x double> %28, i64 2
; CHECK-NEXT:   %34 = insertvalue [3 x double] %32, double %33, 2
; CHECK-NEXT:   store double %mul2, double* %arrayinit.element, align 8
; CHECK-NEXT:   store double %29, double* %"arrayinit.element'ipg", align 8
; CHECK-NEXT:   store double %31, double* %"arrayinit.element'ipg9", align 8
; CHECK-NEXT:   store double %33, double* %"arrayinit.element'ipg10", align 8
; CHECK-NEXT:   %"arrayinit.element3'ipg" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %0, i64 0, i32 0, i64 2
; CHECK-NEXT:   %35 = insertvalue [3 x double*] undef, double* %"arrayinit.element3'ipg", 0
; CHECK-NEXT:   %"arrayinit.element3'ipg11" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %2, i64 0, i32 0, i64 2
; CHECK-NEXT:   %36 = insertvalue [3 x double*] %35, double* %"arrayinit.element3'ipg11", 1
; CHECK-NEXT:   %"arrayinit.element3'ipg12" = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %4, i64 0, i32 0, i64 2
; CHECK-NEXT:   %37 = insertvalue [3 x double*] %36, double* %"arrayinit.element3'ipg12", 2
; CHECK-NEXT:   %arrayinit.element3 = getelementptr inbounds %"struct.std::array", %"struct.std::array"* %agg.result, i64 0, i32 0, i64 2
; CHECK-NEXT:   store double %x, double* %arrayinit.element3, align 8
; CHECK-NEXT:   store double %6, double* %"arrayinit.element3'ipg", align 8
; CHECK-NEXT:   store double %8, double* %"arrayinit.element3'ipg11", align 8
; CHECK-NEXT:   store double %10, double* %"arrayinit.element3'ipg12", align 8
; CHECK-NEXT:   ret void
; CHECK-NEXT: }
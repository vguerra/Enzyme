; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -sroa -simplifycfg -instcombine -adce -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, ...)

@.str = private unnamed_addr constant [18 x i8] c"W(o=%d, i=%d)=%f\0A\00", align 1

define void @derivative(i64* %from, i64* %fromp, i64* %to, i64* %top) {
entry:
  %call = call %struct.Gradients (i8*, ...) @__enzyme_fwdvectordiff(i8* bitcast (void (i64*, i64*)* @callee to i8*), metadata !"enzyme_dup", i64* %from, i64* %fromp, metadata !"enzyme_dup", i64* %to, i64* %top)
  ret void
}

define void @callee(i64* %from, i64* %to) {
entry:
  store i64 ptrtoint ([18 x i8]* @.str to i64), i64* %to
  ret void
}
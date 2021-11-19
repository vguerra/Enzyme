
; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

;  #include <stdlib.h>
;  #include <stdio.h>

;  typedef struct {
;      double x1,x2,x3;
;  } Gradients;

; extern Gradients __enzyme_fwdvectordiff(double (double), ...);

; extern double global;

; __attribute__((noinline))
; double mulglobal(double x) {
;     return x * global;
; }

; __attribute__((noinline))
; Gradients derivative(double x) {
;     return __enzyme_fwdvectordiff(mulglobal, x, (Gradients){1.0,2.0,3.0});
; }

; int main(int argc, char** argv) {
;     double x = atof(argv[1]);
;     printf("x=%f\n", x);
;     Gradients xp = derivative(x);
;     printf("xp=%f\n", xp.x2);
; }

%struct.Gradients = type { double, double, double }

@global = external dso_local local_unnamed_addr global double, align 8, !enzyme_shadow !{<3 x double>* @dglobal}
@dglobal = external dso_local local_unnamed_addr global <3 x double>, align 8

@.str = private unnamed_addr constant [6 x i8] c"x=%f\0A\00", align 1
@.str.1 = private unnamed_addr constant [7 x i8] c"xp=%f\0A\00", align 1

define dso_local double @_Z9mulglobald(double %x) #0 {
entry:
  %0 = load double, double* @global, align 8
  %mul = fmul double %0, %x
  ret double %mul
}

define dso_local void @_Z10derivatived(%struct.Gradients* noalias sret(%struct.Gradients) align 8 %agg.result, double %x) local_unnamed_addr #1 {
entry:
  %agg.tmp = alloca %struct.Gradients, align 8
  %x1 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %agg.tmp, i64 0, i32 0
  store double 1.000000e+00, double* %x1, align 8
  %x2 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %agg.tmp, i64 0, i32 1
  store double 2.000000e+00, double* %x2, align 8
  %x3 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %agg.tmp, i64 0, i32 2
  store double 3.000000e+00, double* %x3, align 8
  call void (%struct.Gradients*, double (double)*, ...) @_Z22__enzyme_fwdvectordiffPFddEz(%struct.Gradients* sret(%struct.Gradients) align 8 %agg.result, double (double)* nonnull @_Z9mulglobald, double %x, %struct.Gradients* nonnull byval(%struct.Gradients) align 8 %agg.tmp)
  ret void
}

declare dso_local void @_Z22__enzyme_fwdvectordiffPFddEz(%struct.Gradients* sret(%struct.Gradients) align 8, double (double)*, ...) local_unnamed_addr #2

define dso_local i32 @main(i32 %argc, i8** nocapture readonly %argv) local_unnamed_addr #3 {
entry:
  %xp = alloca %struct.Gradients, align 8
  %arrayidx = getelementptr inbounds i8*, i8** %argv, i64 1
  %0 = load i8*, i8** %arrayidx, align 8
  %call = call double @atof(i8* %0) #8
  %call1 = call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str, i64 0, i64 0), double %call)
  %1 = bitcast %struct.Gradients* %xp to i8*
  call void @llvm.lifetime.start.p0i8(i64 24, i8* nonnull %1) #9
  call void @_Z10derivatived(%struct.Gradients* nonnull sret(%struct.Gradients) align 8 %xp, double %call)
  %x2 = getelementptr inbounds %struct.Gradients, %struct.Gradients* %xp, i64 0, i32 1
  %2 = load double, double* %x2, align 8
  %call2 = call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([7 x i8], [7 x i8]* @.str.1, i64 0, i64 0), double %2)
  call void @llvm.lifetime.end.p0i8(i64 24, i8* nonnull %1) #9
  ret i32 0
}

declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #4

define available_externally dso_local double @atof(i8* nonnull %__nptr) local_unnamed_addr #5 {
entry:
  %call = call double @strtod(i8* nocapture nonnull %__nptr, i8** null) #9
  ret double %call
}

declare dso_local noundef i32 @printf(i8* nocapture noundef readonly, ...) local_unnamed_addr #6

declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #4

declare dso_local double @strtod(i8* readonly, i8** nocapture) local_unnamed_addr #7

attributes #0 = { noinline norecurse nounwind readonly uwtable willreturn mustprogress "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { noinline uwtable mustprogress "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { norecurse uwtable mustprogress "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { argmemonly nofree nosync nounwind willreturn }
attributes #5 = { inlinehint nounwind readonly uwtable willreturn mustprogress "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #6 = { nofree nounwind "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #7 = { nofree nounwind willreturn "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #8 = { nounwind readonly willreturn }
attributes #9 = { nounwind }


; CHECK: define internal <3 x double> @fwdvectordiffe_Z9mulglobald(double %x, <3 x double> %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = load double, double* @global, align 8
; CHECK-NEXT:   %1 = load <3 x double>, <3 x double>* @dglobal, align 8
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> poison, double %x, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %2 = fmul fast <3 x double> %1, %.splat
; CHECK-NEXT:   %.splatinsert1 = insertelement <3 x double> poison, double %0, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <3 x double> %.splatinsert1, <3 x double> poison, <3 x i32> zeroinitializer
; CHECK-NEXT:   %3 = fmul fast <3 x double> %"x'", %.splat2
; CHECK-NEXT:   %4 = fadd fast <3 x double> %2, %3
; CHECK-NEXT:  ret <3 x double> %4
; CHECK-NEXT: }
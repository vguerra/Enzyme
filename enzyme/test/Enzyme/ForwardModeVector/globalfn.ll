; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(double (double, i64)*, ...) #2

@global = private unnamed_addr constant [1 x void (double*)*] [void (double*)* @ipmul]

@.str = private unnamed_addr constant [6 x i8] c"x=%f\0A\00", align 1
@.str.1 = private unnamed_addr constant [7 x i8] c"xp=%f\0A\00", align 1

define void @ipmul(double* %x) {
entry:
  %0 = load double, double* %x, align 8, !tbaa !2
  %mul = fmul fast double %0, %0
  store double %mul, double* %x
  ret void
}

; Function Attrs: noinline norecurse nounwind readonly uwtable
define dso_local double @mulglobal(double %x, i64 %idx) #0 {
entry:
  %alloc = alloca double
  store double %x, double* %alloc
  %arrayidx = getelementptr inbounds [1 x void (double*)*], [1 x void (double*)*]* @global, i64 0, i64 %idx
  %fp = load void (double*)*, void (double*)** %arrayidx, align 8
  call void %fp(double* %alloc)
  %ret = load double, double* %alloc, !tbaa !2
  ret double %ret
}

; Function Attrs: noinline nounwind uwtable
define dso_local %struct.Gradients @derivative(double %x) local_unnamed_addr #1 {
entry:
  %0 = tail call %struct.Gradients (double (double, i64)*, ...) @__enzyme_fwdvectordiff(double (double, i64)* nonnull @mulglobal, double %x, %struct.Gradients { double 1.0, double 2.0, double 3.0 }, i64 0)
  ret %struct.Gradients %0
}

; Function Attrs: nounwind uwtable
define dso_local void @main(i32 %argc, i8** nocapture readonly %argv) local_unnamed_addr #3 {
entry:
  %arrayidx = getelementptr inbounds i8*, i8** %argv, i64 1
  %0 = load i8*, i8** %arrayidx, align 8, !tbaa !6
  %call.i = tail call fast double @strtod(i8* nocapture nonnull %0, i8** null) #2
  %call1 = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str, i64 0, i64 0), double %call.i)
  %call2 = tail call %struct.Gradients @derivative(double %call.i)
  %1 = extractvalue %struct.Gradients %call2, 0
  %call3 = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.1, i64 0, i64 0), double %1)
  ret void
}

; Function Attrs: nounwind
declare dso_local i32 @printf(i8* nocapture readonly, ...) local_unnamed_addr #4

; Function Attrs: nounwind
declare dso_local double @strtod(i8* readonly, i8** nocapture) local_unnamed_addr #4

attributes #0 = { noinline norecurse nounwind readonly uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #1 = { noinline nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #2 = { nounwind }
attributes #3 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #4 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 7.1.0 "}
!2 = !{!3, !3, i64 0}
!3 = !{!"double", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !4, i64 0}


; CHECK: @global_shadow = private unnamed_addr constant [1 x void (double*)*] [void (double*)* bitcast (void (double*, [3 x double*])** @"_enzyme_forwardvector_ipmul'" to void (double*)*)]
; CHECK: @"_enzyme_forwardvector_ipmul'" = internal constant void (double*, [3 x double*])* @fwdvectordiffeipmul

; CHECK: define internal void @fwdvectordiffeipmul(double* %x, [3 x double*] %"x'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = load double, double* %x
; CHECK-NEXT:   %1 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   %2 = load double, double* %1
; CHECK-NEXT:   %3 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   %4 = load double, double* %3
; CHECK-NEXT:   %5 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   %6 = load double, double* %5
; CHECK-NEXT:   %mul = fmul fast double %0, %0
; CHECK-NEXT:   %7 = insertelement <3 x double> undef, double %2, i64 0
; CHECK-NEXT:   %8 = insertelement <3 x double> %7, double %4, i64 1
; CHECK-NEXT:   %9 = insertelement <3 x double> %8, double %6, i64 2
; CHECK-NEXT:   %10 = insertelement <3 x double> undef, double %2, i64 0
; CHECK-NEXT:   %11 = insertelement <3 x double> %10, double %4, i64 1
; CHECK-NEXT:   %12 = insertelement <3 x double> %11, double %6, i64 2
; CHECK-NEXT:   %.splatinsert = insertelement <3 x double> {{(poison|undef)}}, double %0, i32 0
; CHECK-NEXT:   %.splat = shufflevector <3 x double> %.splatinsert, <3 x double> {{(poison|undef)}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %13 = fmul fast <3 x double> %9, %.splat
; CHECK-NEXT:   %.splatinsert1 = insertelement <3 x double> {{(poison|undef)}}, double %0, i32 0
; CHECK-NEXT:   %.splat2 = shufflevector <3 x double> %.splatinsert1, <3 x double> {{(poison|undef)}}, <3 x i32> zeroinitializer
; CHECK-NEXT:   %14 = fmul fast <3 x double> %12, %.splat2
; CHECK-NEXT:   %15 = fadd fast <3 x double> %13, %14
; CHECK-NEXT:   %16 = extractelement <3 x double> %15, i64 0
; CHECK-NEXT:   %17 = extractelement <3 x double> %15, i64 1
; CHECK-NEXT:   %18 = extractelement <3 x double> %15, i64 2
; CHECK-NEXT:   store double %mul, double* %x
; CHECK-NEXT:   %19 = extractvalue [3 x double*] %"x'", 0
; CHECK-NEXT:   store double %16, double* %19
; CHECK-NEXT:   %20 = extractvalue [3 x double*] %"x'", 1
; CHECK-NEXT:   store double %17, double* %20
; CHECK-NEXT:   %21 = extractvalue [3 x double*] %"x'", 2
; CHECK-NEXT:   store double %18, double* %21
; CHECK-NEXT:   ret void
; CHECK-NEXT: }
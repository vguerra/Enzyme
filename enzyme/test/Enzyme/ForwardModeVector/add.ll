; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -mem2reg -instsimplify -simplifycfg -S | FileCheck %s

%struct.Gradients = type { double, double }

define double @tester(double %x, double %y) {
entry:
  %add = fadd double %x, %y
  ret double %add
}

define %struct.Gradients @test_derivative(double %x, double %y){
entry:
  %call = call %struct.Gradients (double (double, double)*, ...) @__enzyme_fwdvectordiff(double (double, double)* nonnull @tester, double %x, [2 x double] [double 1.000000e+00, double 0.000000e+00], double %y, [2 x double] [double 0.000000e+00, double 1.000000e+00])
  ret %struct.Gradients %call
}

declare %struct.Gradients @__enzyme_fwdvectordiff(double (double, double)*, ...)

attributes #0 = { norecurse nounwind readnone ssp uwtable willreturn "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { ssp uwtable "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }


; CHECK: define internal {{(dso_local )?}}<2 x double> @fwdvectordiffetester(double %x, <2 x double> %"x'", double %y, <2 x double> %"y'")
; CHECK-NEXT: entry:
; CHECK-NEXT:   %0 = fadd fast <2 x double> %"x'", %"y'"
; CHECK-NEXT:   ret <2 x double> %0
; CHECK-NEXT: }
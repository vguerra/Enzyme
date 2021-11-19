; RUN: %opt < %s %loadEnzyme -enzyme -enzyme-preopt=false -inline -mem2reg -instsimplify -adce -loop-deletion -correlated-propagation -simplifycfg -early-cse -S | FileCheck %s

%struct.Gradients = type { double, double, double }

; Function Attrs: nounwind
declare %struct.Gradients @__enzyme_fwdvectordiff(i8*, double*, %struct.Gradients*, double**, %struct.Gradients**, i64)

; Function Attrs: noinline nounwind uwtable
define dso_local void @f(double* %x, double** %y, i64 %n) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.body, %entry
  %i.0 = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %cmp = icmp ule i64 %i.0, %n
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds double, double* %x, i64 0
  %0 = load double, double* %arrayidx
  %1 = load double*, double** %y
  %2 = load double, double* %1
  %add = fadd fast double %2, %0
  store double %add, double* %1
  %inc = add i64 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: noinline nounwind uwtable
define dso_local %struct.Gradients @dsumsquare(double* %x, %struct.Gradients* %xp, double** %y, %struct.Gradients** %yp, i64 %n) #0 {
entry:
  %call = call %struct.Gradients @__enzyme_fwdvectordiff(i8* bitcast (void (double*, double**, i64)* @f to i8*), double* %x, %struct.Gradients* %xp, double** %y, %struct.Gradients** %yp, i64 %n)
  ret %struct.Gradients %call
}

attributes #0 = { noinline nounwind uwtable }

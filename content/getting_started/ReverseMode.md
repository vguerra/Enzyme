# Reverse-Mode Differentiation

Reverse-mode differentiation and, in fact, differentiation in general is all about chain rule. We know from Calculus that we can differentiate a given composition $h(g(f(x)))$ via 

$$ \operatorname d h = \frac{dh}{dg} \left(\frac{dg}{df} \left(\frac{df}{dx} \operatorname d x \right) \right) .$$

This method is called `forward-mode` and it is mostly used when there are one input and multiple outputs. While forward-mode differentiation is more efficient than other methods, the Scientific Community has shown more interest in cases where there are multiple inputs and a single output. This can be obtained via `reverse-mode` differentiation. Rearranging the parentheses in the expression above, we will have

$$ \operatorname d h = \left( \left( \left( \frac{dh}{dg} \right) \frac{dg}{df} \right) \frac{df}{dx} \right) \operatorname d x $$

which we can compute with `reverse-mode` via

$$ \underbrace{\bar x}_{\frac{dh}{dx}} = \underbrace{\bar g \frac{dg}{df}}_{\bar f} \frac{df}{dx} .$$

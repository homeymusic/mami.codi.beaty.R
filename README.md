MaMi.CoDi.Beaty: A Model of Harmony Perception
================

# Behavioral

## Manipulating Harmonic Frequencies

##### Harmonic ~ Partials: 10

![](man/figures/README-unnamed-chunk-4-1.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-2.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-3.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-4.png)<!-- -->

##### 5Partials ~ Partials: 5

![](man/figures/README-unnamed-chunk-4-5.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-6.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-7.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-8.png)<!-- -->

##### 5PartialsNo3 ~ Partials: 5

![](man/figures/README-unnamed-chunk-4-9.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-10.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-11.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-12.png)<!-- -->

##### Bonang ~ Partials: 4

![](man/figures/README-unnamed-chunk-4-13.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-14.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-15.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-16.png)<!-- -->

#### Dyads spanning 15 semitones

##### Pure ~ Partials: 1

![](man/figures/README-unnamed-chunk-4-17.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-18.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-19.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-20.png)<!-- -->

##### Stretched ~ Partials: 10

![](man/figures/README-unnamed-chunk-4-21.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-22.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-23.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-24.png)<!-- -->

##### Compressed ~ Partials: 10

![](man/figures/README-unnamed-chunk-4-25.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-26.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-27.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-28.png)<!-- -->

#### Dyads spanning 1 quarter tone

##### M3 ~ Partials: 10

![](man/figures/README-unnamed-chunk-4-29.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-30.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-31.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-32.png)<!-- -->

##### M6 ~ Partials: 10

![](man/figures/README-unnamed-chunk-4-33.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-34.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-35.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-36.png)<!-- -->

##### P8 ~ Partials: 10

![](man/figures/README-unnamed-chunk-4-37.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-38.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-39.png)<!-- -->  
![](man/figures/README-unnamed-chunk-4-40.png)<!-- -->

# Theory

## Heisenberg Uncertainty

$$
\Delta x \Delta p \ge \frac{\hbar}{2}
$$

## Gabor Uncertainty

$$
\Delta t \Delta \omega \ge \frac{1}{2}
$$

## Relative Uncertainty

### Reference Time Period

$$
\Delta t = T_{ref} = n \frac{2 \pi }{\omega_{ref}}, \quad n \enspace \text{periods}
$$ $$
\Delta t \Delta \omega = T_{ref} \Delta \omega = n \frac{2 \pi}{\omega_{ref}}\Delta \omega \ge \frac{1}{2}
$$

### Relative Uncertainty

$$
\frac{\Delta \omega}{\omega_{ref}} \ge \frac{1}{4 \pi n} \quad \text{and} \quad \frac{\Delta f}{f_{ref}} \ge \frac{1}{4 \pi n}\
$$

## Rational Approximation Uncertainty

### Relative Rational Approximation

$$
\Delta f = \bigl| f - \widetilde f \bigr| \quad \text{where} \quad \widetilde f = f_{ref} \frac{a}{b} \quad
\text{and} \quad a \in \mathbb{Z}, b \in \mathbb{N}
$$

$$
\Delta f = f_{ref} \bigl| \frac{f}{f_{ref}} - \frac{a}{b} \bigr|
$$

$$
\frac{\Delta f}{f_{ref}} =  \frac{f_{ref} \bigl| \frac{f}{f_{ref}} - \frac{a}{b} \bigr|}{f_{ref}}  = \bigl| \frac{f}{f_{ref}} - \frac{a}{b}\bigr| \ge \frac{1}{4 \pi n}
$$

$$
\bigl| \frac{f}{f_{ref}} - \frac{a}{b}\bigr| \ge \frac{1}{4 \pi n}
$$

## Stern-Brocot: Traversal

$$
\begin{aligned}
&\mathbf{WHILE} \Bigl|\tfrac{f}{f_{\mathrm{ref}}}-\tfrac{a}{b}\Bigr| \ge \tfrac{1}{4\pi n}
\quad\mathbf{DO}\\
&\quad a  \gets  a_{\mathrm{left}} + a_{\mathrm{right}}\\
&\quad b  \gets  b_{\mathrm{left}} + b_{\mathrm{right}}\\
&\quad \mathbf{IF} \tfrac{f}{f_{\mathrm{ref}}} > \tfrac{a}{b} \mathbf{THEN}\\
&\quad\quad a_{\mathrm{left}} \gets a,\quad b_{\mathrm{left}} \gets b\\
&\quad \mathbf{ELSE}\\
&\quad\quad a_{\mathrm{right}} \gets a,\quad b_{\mathrm{right}} \gets b\\
&\quad \mathbf{END\_IF}\\
&\quad \delta \gets \delta + 1\\
&\mathbf{END\_WHILE}
\end{aligned}
$$

### Stern–Brocot: Rational Fractions Lowest Terms

$$
a \perp b \quad \Longrightarrow \quad  \mathrm{gcd}(a,b)=1
$$

### Stern–Brocot: Total Traversal Depth for All Tones in a Chord

$$
\Delta \;=\; \sum_{i=1}^{N} \delta_{i}
$$

## Fundamental Frequency

$$
f_0 = f_{ref}\frac{\mathrm{gcd}(a_1, a_2, \dots, a_N)}{\mathrm{lcm}(b_1, b_2, \dots, b_N)}, \quad a_i \perp b_i
$$

## Fundamental Wavelength

$$
\lambda_0 = \lambda_{ref}\frac{\mathrm{gcd}(a_1, a_2, \dots, a_N)}{\mathrm{lcm}(b_1, b_2, \dots, b_N)}, \quad a_i \perp b_i
$$

## Stolzenburg Periodicity Perception

### Fundamental Cycle Length

$$
\Lambda  = \mathrm{lcm}(b_1,b_2,\dots,b_N) \quad \text{when} \quad \gcd(a_1,\dots,a_N)=1
$$

### Psychophysical Periodicity

$$
\psi  = \log_2 \bigl(\Lambda\bigr) \quad \bigl[\text{units: Sz}\bigr]
$$

#### Major-Minor: Temporal and Spatial Periodicity Difference

$$
\Psi_{MaMi}  = \psi_{t} - \psi_{x} \quad \bigl[\text{units: Sz}\bigr]
$$

#### Consonance-Dissonance: Temporal and Spatial Periodicity Sum

$$
\Psi_{CoDi}  = \psi_{t} + \psi_{x} \quad \bigl[\text{units: Sz}\bigr]
$$

#### Beating: Stern-Brocot Traversal Depth

$$
\Psi_{Beaty} = \log_{2}(\Delta)
$$

## Pseudo-Octaves: Perception of Stretching and Compressing

$$
\begin{aligned}
&\mathbf{FOR}\; i \gets 1 \;\mathbf{TO}\; N \;\mathbf{DO}\\
&\quad \mathbf{FOR}\; j \gets i+1 \;\mathbf{TO}\; N \;\mathbf{DO}\\
&\quad\quad \mathrm{approximation} \gets \dfrac{\mathrm{ratios}[i]}{\mathrm{ratios}[j]}\\
&\quad\quad \mathrm{ideal} \gets \mathrm{round}(\mathrm{approximation})\\
&\quad\quad \mathbf{IF}\;\dfrac{\lvert \mathrm{ideal} - \mathrm{approximation}\rvert}{\mathrm{ideal}} < \log_{2}\!\bigl(1 + \tfrac{1}{4\pi\,n}\bigr)\;\mathbf{THEN}\\
&\quad\quad\quad \mathrm{octave_{\mathrm{pseudo}}} \gets 2^{\,\frac{\ln(\mathrm{approximation})}{\ln(\mathrm{ideal})}}\\
&\quad\quad\quad \mathrm{candidates} \gets \mathrm{candidates} \,\cup\, \{\mathrm{octave_{\mathrm{pseudo}}}\}\\
&\quad\quad \mathbf{END\_IF}\\
&\quad \mathbf{END\_FOR}\\
&\mathbf{END\_FOR}\\
&\mathbf{RETURN}\;\mathrm{most\_frequent}(\mathrm{candidates})\\
\end{aligned}
$$

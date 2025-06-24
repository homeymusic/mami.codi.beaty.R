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

## New: Relative Uncertainty

### Reference Period of Observation

$$
\Delta t \equiv T_{ref} = \frac{2 \pi}{\omega_{ref}}
$$ $$
\Delta t \Delta \omega = T_{ref} \Delta \omega_i = \frac{2 \pi}{\omega_{ref}} \Delta \omega_i \ge \frac{1}{2}
$$

### Relative Uncertainty

$$
\frac{\Delta \omega_i}{\omega_{ref}} \ge \frac{1}{4 \pi} \quad \text{and} \quad \frac{\Delta f_i}{f_{ref}} \ge \frac{1}{4 \pi}\
$$

### Rational Fraction Approximation

$$
\Delta f_i = \bigl| f_i - \widetilde f_i\bigr|
$$

$$
\Delta f_i = f_{ref} \bigl| \frac{f_i}{f_{ref}} - \frac{p}{q} \bigr|, \quad p \perp q
$$

$$
\frac{\Delta f_i}{f_{ref}} = \bigl| \frac{f_i}{f_{ref}} - \frac{p}{q}\bigr| \ge \frac{1}{4 \pi}\
$$

### Stern-Brocot Traversal

$$
\begin{aligned}
&\mathbf{WHILE}\;\Bigl|\tfrac{f_i}{f_{\mathrm{ref}}}-\tfrac{p}{q}\Bigr|\;\ge\;\tfrac{1}{4\pi}
\quad\mathbf{DO}\\
&\quad p \;\gets\; p_{\mathrm{left}} + p_{\mathrm{right}}\\
&\quad q \;\gets\; q_{\mathrm{left}} + q_{\mathrm{right}}\\
&\quad \mathbf{IF}\;\tfrac{f_i}{f_{\mathrm{ref}}} > \tfrac{p}{q}\;\mathbf{THEN}\\
&\quad\quad p_{\mathrm{left}}\;\gets\;p,\quad q_{\mathrm{left}}\;\gets\;q\\
&\quad \mathbf{ELSE}\\
&\quad\quad p_{\mathrm{right}}\;\gets\;p,\quad q_{\mathrm{right}}\;\gets\;q\\
&\quad \mathbf{END\_IF}\\
&\mathbf{END\_WHILE}
\end{aligned}
$$

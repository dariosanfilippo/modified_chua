// =============================================================================
//      Modified Chua complex generator
// ============================================================================= 
//
//  Complex sound generator based on modified Chua equations.
//  The model is structurally-stable through hyperbolic tangent function
//  saturators and allows for parameters in unstable ranges to explore 
//  different dynamics. Furthermore, this model includes DC-blockers in the 
//  feedback paths to counterbalance a tendency towards fixed-point attractors 
//  – thus enhancing complex behaviours – and obtain signals suitable for audio.
//  Besides the original parameters in the model, this system includes a
//  saturating threshold determining the positive and negative bounds in the
//  equations, while the output peaks are within the [-1.0; 1.0] range.
//
//  The system can be triggered by an impulse or by a constant of arbitrary
//  values for deterministic and reproducable behaviours. Alternatively,
//  the oscillator can be fed with external inputs to be used as a nonlinear
//  distortion unit.
//
// =============================================================================

import("stdfaust.lib");

declare name "Modified Chua complex generator";
declare author "Dario Sanfilippo";
declare copyright "Copyright (C) 2021 Dario Sanfilippo
    <sanfilippo.dario@gmail.com>";
declare version "1.1";
declare license "GPL v3.0 license";

chua(l, a, b, alpha, k, beta, yps, dt, x_0, y_0, z_0) = x_level(out * (x / l)) , 
                                                        y_level(out * (y / l)) , 
                                                        z_level(out * (z / l))
    letrec {
        'x = fi.highpass(1, 10, tanh(l, (x_0 + x + (k * alpha * (y - x - f(x))) 
            * dt)));
        'y = fi.highpass(1, 10, tanh(l, (y_0 + y + (k * (x - y + z)) * dt)));
        'z = fi.highpass(1, 10, tanh(l, (z_0 + z + (-k * (beta * y + yps * z)) 
            * dt)));
    }
    with {
        f(x) = b * x + .5 * (a - b) * (abs(x + 1) - abs(x - 1));
    };

// smoothing function for click-free parameter variations using 
// a one-pole low-pass with a 20-Hz cut-off frequency.
smooth(x) = fi.pole(pole, x * (1.0 - pole))
    with {
        pole = exp(-2.0 * ma.PI * 20.0 / ma.SR);
    };

// tanh() saturator with adjustable saturating threshold
tanh(l, x) = l * ma.tanh(x / l);

// GUI parameters
x_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[00]x[style:dB]", -60, 0)));
y_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[01]y[style:dB]", -60, 0)));
z_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[02]z[style:dB]", -60, 0)));
global_group(x) = vgroup("[0]Global", x);
levels_group(x) = hgroup("[1]Levels (dB)", x);
a = global_group(hslider("[04]a[scale:exp]", 1, 0, 20, .000001) : smooth);
b = global_group(hslider("[05]b[scale:exp]", 3, 0, 20, .000001) : smooth);
alpha = global_group(hslider("[06]alpha[scale:exp]", 2, 0, 20, .000001) 
    : smooth);
k = global_group(hslider("[07]k[scale:exp]", 1, 0, 20, .000001) : smooth);
beta = global_group(hslider("[08]beta[scale:exp]", 5, 0, 20, .000001) : smooth);
yps = global_group(hslider("[09]yps[scale:exp]", 1, 0, 20, .000001) : smooth);
dt = global_group(
    hslider("[10]dt (integration step)[scale:exp]", 0.1, 0.000001, 1, .000001) 
        : smooth);
input(x) = global_group(nentry("[03]Input value", 1, 0, 10, .000001) 
    <: _ * impulse + _ * checkbox("[01]Constant inputs") 
        + x * checkbox("[00]External inputs"));
impulse = button("[02]Impulse inputs") : ba.impulsify;
limit = global_group(
    hslider("[11]Saturation limit[scale:exp]", 4, 1, 1024, .000001) : smooth);
out = global_group(hslider("[12]Output scaling[scale:exp]", 0, 0, 1, .000001) 
    : smooth);

process(x1, x2, x3) = chua(limit, a, b, alpha, k, beta, yps, dt, 
    input(x1), input(x2), input(x3));

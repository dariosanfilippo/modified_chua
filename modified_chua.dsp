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
    levels_group(hbargraph("[5]x[style:dB]", -60, 0)));
y_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[6]y[style:dB]", -60, 0)));
z_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[7]z[style:dB]", -60, 0)));
global_group(x) = vgroup("[1]Global", x);
levels_group(x) = hgroup("[5]Levels (dB)", x);
a = global_group(hslider("[1]a[scale:exp]", 1, 0, 20, .000001) : smooth);
b = global_group(hslider("[2]b[scale:exp]", 3, 0, 20, .000001) : smooth);
alpha = global_group(hslider("[3]alpha[scale:exp]", 2, 0, 20, .000001) 
    : smooth);
k = global_group(hslider("[4]k[scale:exp]", 1, 0, 20, .000001) : smooth);
beta = global_group(hslider("[5]beta[scale:exp]", 5, 0, 20, .000001) : smooth);
yps = global_group(hslider("[6]yps[scale:exp]", 1, 0, 20, .000001) : smooth);
dt = global_group(
    hslider("[9]dt (integration step)[scale:exp]", 0.1, 0.000001, 1, .000001) 
        : smooth);
input(x) = global_group(nentry("[3]Input value", 1, 0, 10, .000001) 
    <: _ * impulse + _ * checkbox("[1]Constant inputs") 
        + x * checkbox("[0]External inputs"));
impulse = checkbox("[2]Impulse inputs") <: _ - _' : abs;
limit = global_group(
    hslider("[9]Saturation limit[scale:exp]", 4, 1, 1024, .000001) : smooth);
out = global_group(hslider("[9]Output scaling[scale:exp]", 0, 0, 1, .000001) 
    : smooth);

process(x1, x2, x3) = chua(limit, a, b, alpha, k, beta, yps, dt, 
    input(x1), input(x2), input(x3));

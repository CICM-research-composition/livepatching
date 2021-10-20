import("stdfaust.lib");
n = 8;
fc = hslider("v:filters/fc [unit:Hz]", 440, 20, 2000, 0.01);
q = hslider("v:filters/q", 30, 1, 500, 1);
gain = hslider("v:filters/gain", 0.2, 0, 1, 0.01);
source = no.multinoise(n);
//
tempo = hslider("tempo", 60, 10, 600, 1);
nsamp = int(60 / tempo * ma.SR);
//
process = source : par(i, n, (*(ba.pulsen(1, nsamp)) : fi.resonbp(fc*(i+1), q, gain))) :> (_, _);

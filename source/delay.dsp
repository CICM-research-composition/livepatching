import("stdfaust.lib");

//--------------------------------------------------------------------------------------//
//A delay chain
//--------------------------------------------------------------------------------------//


//--------------------------------------------------------------------------------------//
//CONSTANTS
//--------------------------------------------------------------------------------------//
//Maximum number of samples if a common delay line
//corresponding to a bit more than 5 seconds at 48 KHz
Ndelsamp = 262144;

//Number of samples for a millisecond of sound
millisec = ma.SR / 1000.0;

//Dynamics in dB relative to the original sound//
id = 0; //identical amplitude as the original sound//
bl = -6; //a bit lower than the original amplitude//
ml = -12; //much lower than the original amplitude//
vl = -24; //very low amplitude//

//--------------------------------------------------------------------------------------//
//PARAMETERS OF CONTROL
//--------------------------------------------------------------------------------------//
//general tempo of the structure//
tempo = nentry("tempo", 60, 1, 10000, 1);

//local amplitude of the structure//
vol = nentry("vol", 1, 0, 1, 0.01) : si.smoo;

//feedback of reinjection from the last delay to the first one//
fdbk = nentry("fdbk", 0, 0, 0.99999, 0.001);

//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//
//RYTHMICAL AND DYNAMIC STRUCTURE
//TO BE ADAPTED BY EACH USER
//--------------------------------------------------------------------------------------//
//list of durations of delays//
//4 stands for a whole, 2 for a half note, 1 for a quarter note, 0.5 for an eighth, 0.25 for a fourth, etc.
//the first value 0 means we listen to the original note at once//

rythm = (0, 0.25, 0.75, 0.5, 3.5, 0.5, 1.75, 0.75);

//list of dynamics//
//id = identical amplitude as the original sound//
//bl = a bit lower than the original amplitude//
//ml = much lower than the original amplitude//
//vl = very low amplitude//
//there must be the same number of values as in the rythm list//

dynamics = (id, vl, bl, ml, ml, ml, ml, ml);

//--------------------------------------------------------------------------------------//
//END OF THE STRUCTURE TO BE ADAPTED
//--------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------------//



//--------------------------------------------------------------------------------------//
//DEFINITION OF AN ELEMENTARY DELAY LINE
//--------------------------------------------------------------------------------------//
//durations in samples of each elementary delay, with a maximum of Ndelsamp//
dur(i) = (ba.take(i, rythm) * 60 / tempo * ma.SR, Ndelsamp) : min ;
del(i) = de.sdelay(Ndelsamp, 16, dur(i));

//--------------------------------------------------------------------------------------//
//RECURSIVE DEFINITION OF A DELAY CHAIN
//--------------------------------------------------------------------------------------//
delaychain(1) = del(1);
delaychain(2) = del(1) <: (del(2), _);
delaychain(n) = delaychain(n-1) : ((_ <: (del(n), _)), si.bus(n-2));

//definition of the structure//
struct = delaychain(Nind) : par(i, Nind, *(ba.db2linear((ba.take(Nind-i, dynamics))))) with {
	Nind = ba.count(rythm);
};

process = (+ : struct) ~ (*(fdbk)) :toVol(Nind) : toStereo(Nind) with {
	toVol(n) = par(i, n, *(vol));
	//left to right panning//
	toStereo(n) = par(i, n, sp.panner(1 - i / (n-1))) :> (_, _);
	Nind = ba.count(rythm);
};

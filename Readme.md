# an.intergrated.INS.GPS.kalman.m
	For octave Octave-5.1.0.0, I had to update these files, from a development branch at octave.org
	+ annotation.m 
	+ axis.m 
	+ gtext.m 
	+ legend.m 
	+ orient.m 
	+ shading.m
	Otherwise, an error of 
	error: axis: LIMITS(3) must be less than LIMITS(4)
	
	
	To run: 
	On Octave Octave-5.1.0.0  Windows 10
	line 10:  minutes = 1; % original was 6
	line 16: 1/delta_t * 2 * minutes % original was 1/delta * 60
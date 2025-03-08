All codes designed for triangular mesh and Power Law error model. You can choose between Lippmann, DAS1, or SuperSting resistivity files. Ideally, you shouldn't have to change anything that isn't in user defined parameters section.

You'll need:
Statistics toolbox
Fillout for plot_res.m

Inversion Codes: <br />
R2SingleSurvey.m = single survey inversion <br />
R2TimeLapseDD.m = time lapse inversion via data differencing <br />
R2TimeLapseMD.m = time lapse inversion via model differencing (calculates *_diffres.dat for you) <br /> <br />

Preprocessing Codes: <br />
preproc_Pwl.m = preprocessing and writing protocol.dat with Power Law error model <br /> <br />



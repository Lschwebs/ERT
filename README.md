All codes designed for triangular mesh and Power Law error model. You can choose between Lippmann, DAS1, or SuperSting resistivity files. Ideally, you shouldn't have to change anything that isn't in user defined parameters section.

You'll need:
Statistics toolbox and Fillout for plot_res.m <br />
In working directory you MUST have folder named 'results' with subfolders 'ref', 'R2in', 'R2out', 'protocol', 'errMod' (see examples) <br /><br />

Inversion Codes: <br />
R2SingleSurvey.m = single survey inversion <br />
R2TimeLapseDD.m = time lapse inversion via data differencing <br />
R2TimeLapseMD.m = time lapse inversion via model differencing (calculates *_diffres.dat for you) <br /> <br />

Preprocessing Codes: <br />
preproc_fr_Pwl.m = preprocessing and writing protocol.dat with Power Law error model for FULL RECIPROCALS <br /> <br />
preproc_SSerr_Pwl.m = preprocessing and writing protocol.dat with Power Law error model for SuperSting with partial reciprocals. Code uses stacking errors to filter data and reciprocal errors to build error model that is applied to all data <br /> <br />




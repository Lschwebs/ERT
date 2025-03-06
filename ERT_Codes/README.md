All inversion codes can use the same writeR2.m, importLippmann.m, plot_res.m, and PwlErrMod.m (if using an error model). <br />
Must use different preprocessing codes for different inversion codes! <br />

Inversion Codes: <br />
R2SingleSurvey.m = single survey inversion <br />
R2TimeLapseDD.m = time lapse inversion via data differencing <br />
R2TimeLapseMD.m = time lapse inversion via model differencing <br /> <br />

Preprocessing Codes: <br />
For single survey or model differencing: <br />
preprocLipp.m = preprocessing and writing protocol.dat with no error model and no background survey <br />
preprocLipp_Pwl.m = preprocessing and writing protocol.dat with Power Law error model and no background survey <br /> <br />

For data differencing: <br />
preprocLippDD.m = preprocessing and writing protocol.dat with a background survey and no error model  <br />
preprocDD_Pwl.m = preprocessing and writing protocol.dat with a background survey and Power Law error model  <br />






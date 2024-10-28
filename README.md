All inversion codes can use the same writeR2.m, importLippmann.m, plot_res.m, and PwlErrMod.m (if using an error model).
Must use different preprocessing codes for different inversion codes!

Inversion Codes:
R2SingleSurvey.m = single survey inversion
R2TimeLapseDD.m = time lapse inversion via data differencing 
R2TimeLapseMD.m = time lapse inversion via model differencing

Preprocessing Codes:
preprocLipp.m = preprocessing and writing protocol.dat with no error model and no background survey
preprocLipp_





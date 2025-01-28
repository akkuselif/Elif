libname IPEDS '~/IPEDS';
LIBNAME VIYAREPO '~/VIYAREPO';
options fmtsearch=(IPEDS);

proc sql;
	create table FinalTableV1 as
	select *, 
	case
		when tuition1 ne tuition2 then 1
	else 0
	end as InDistrictT, 
	abs(tuition2 - tuition1) as InDistrictTDiff,
	case
		when fee1 ne fee2 then 1
	else 0
	end as InDistrictF, 
	abs(fee2 - fee1) as InDistrictFDiff,
/* 	tuition2 as InStateT, fee2 as InstateF, */
	case
		when tuition3 ne tuition2 then 1
	else 0
	end as OutStateT,
	abs(tuition3 - tuition2) as OutStateTDiff,   
	case
		when fee3 ne fee2 then 1
	else 0
	end as OutStateF, 
	abs(fee3 - fee2) as OutStateFDiff
	from viyarepo.finaltable;
quit;

data FinalTableV2;
    set FinalTableV1 (rename=(tuition2=InStateT fee2=InstateF));
run;

proc sql;
	create table FinalTableV2 as
	select *, 
	case
		when tuition1 ne tuition2 then 1
	else 0
	end as InDistrictT, 
	abs(tuition2 - tuition1) as InDistrictTDiff,
	case
		when fee1 ne fee2 then 1
	else 0
	end as InDistrictF, 
	abs(fee2 - fee1) as InDistrictFDiff,
	case
		when tuition3 ne tuition2 then 1
	else 0
	end as OutStateT,
	abs(tuition3 - tuition2) as OutStateTDiff,   
	case
		when fee3 ne fee2 then 1
	else 0
	end as OutStateF, 
	abs(fee3 - fee2) as OutStateFDiff,
	tuition2 as InStateT, 
	fee2 as InstateF
	from viyarepo.finaltable;
quit;


/* proc sort data=PREIPEDSMRGD out=VIYAREPO.FINALTABLE nodupkey; */
/*     by unitid; */
/* run; */
/* proc compare base=VIYAREPO.FINALTABLE compare=WORK.ipedsmerged */
/* 			out=comparison  outnoequal; */
/* run; */
libname IPEDS '~/IPEDS';
LIBNAME VIYAREPO '~/VIYAREPO';
options fmtsearch=(IPEDS);

proc sql;
	create table FinalTableV1 as
	select *, 
	case
		when tuition1 ne tuition2 then 1
	else 0
	end as InDistrictT, 
	abs(tuition2 - tuition1) as InDistrictTDiff,
	case
		when fee1 ne fee2 then 1
	else 0
	end as InDistrictF, 
	abs(fee2 - fee1) as InDistrictFDiff,
/* 	tuition2 as InStateT, fee2 as InstateF, */
	case
		when tuition3 ne tuition2 then 1
	else 0
	end as OutStateT,
	abs(tuition3 - tuition2) as OutStateTDiff,   
	case
		when fee3 ne fee2 then 1
	else 0
	end as OutStateF, 
	abs(fee3 - fee2) as OutStateFDiff
	from viyarepo.finaltable;
quit;

data FinalTableV2;
    set FinalTableV1 (rename=(tuition2=InStateT fee2=InstateF));
run;

proc sql;
	create table FinalTableV2 as
	select *, 
	case
		when tuition1 ne tuition2 then 1
	else 0
	end as InDistrictT, 
	abs(tuition2 - tuition1) as InDistrictTDiff,
	case
		when fee1 ne fee2 then 1
	else 0
	end as InDistrictF, 
	abs(fee2 - fee1) as InDistrictFDiff,
	case
		when tuition3 ne tuition2 then 1
	else 0
	end as OutStateT,
	abs(tuition3 - tuition2) as OutStateTDiff,   
	case
		when fee3 ne fee2 then 1
	else 0
	end as OutStateF, 
	abs(fee3 - fee2) as OutStateFDiff,
	tuition2 as InStateT, 
	fee2 as InstateF
	from viyarepo.finaltable;
quit;


/* proc sort data=PREIPEDSMRGD out=VIYAREPO.FINALTABLE nodupkey; */
/*     by unitid; */
/* run; */
/* proc compare base=VIYAREPO.FINALTABLE compare=WORK.ipedsmerged */
/* 			out=comparison  outnoequal; */
/* run; */

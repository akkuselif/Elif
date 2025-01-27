libname IPEDS '~/IPEDS';
LIBNAME VIYAREPO '~/VIYAREPO';
options fmtsearch=(IPEDS); 


data CharaPred (keep=unitid iclevel--cbsatype);
	set ipeds.characteristics;
	by unitid;
run;

proc sql;
    create table AidPred as
    select unitid,
		   (uagrntn / scfa2) as GrantRate format=percentn8.2,
		   (uagrntt / scfa2) as GrantAvg,
		   (upgrntn / scfa2) as PellRate format=percentn8.2,
		   (ufloann / scfa2) as LoanRate format=percentn8.2,
		   (ufloant / scfa2) as LoanAvg
    from ipeds.aid;
quit;

data TuitionPred (keep=unitid tuition1--boardamt);
	set ipeds.tuitionandcosts;
	by unitid;
run;

proc sql;
	create table SalPred as
	select salaries.unitid, 
		   sum(sa09mot) / sum(sa09mct) as AvgSalary,
		   mean(scfa2) / sum(sa09mct) as StuFacRatio format=comma5.1
	from ipeds.salaries inner join ipeds.aid
	on salaries.unitid = aid.unitid
	group by salaries.unitid;;
quit;

data PREIPEDSMRGD;
	merge ipeds.gradrates CharaPred AidPred TuitionPred SalPred;
	by unitid;
run;


proc sort data=PREIPEDSMRGD out=VIYAREPO.FINALTABLE nodupkey;
    by unitid;
run;

/*  */
/* proc compare base=VIYAREPO.FINALTABLE compare=WORK.ipedsmerged */
/* 			out=comparison  outnoequal; */
/* run; */
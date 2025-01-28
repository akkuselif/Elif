libname IPEDS '~/IPEDS';
LIBNAME ElifGit '~/ElifGit';
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


proc sort data=PREIPEDSMRGD out=EliFgit.FINALTABLE nodupkey;
    by unitid;
run;

proc sql;
    create table TuitionUpdate as
    select unitid,
           case when tuition1 ne tuition2 then 1 else 0 end as InDistrictT,
           abs(tuition1 - tuition2) as InDistrictTDiff,
           case when fee1 ne fee2 then 1 else 0 end as InDistrictF,
           abs(fee1 - fee2) as InDistrictFDiff,
           tuition2 as InStateT,
           fee2 as InStateF,
           case when tuition3 ne tuition2 then 1 else 0 end as OutStateT,
           abs(tuition3 - tuition2) as OutStateTDiff,
           case when fee3 ne fee2 then 1 else 0 end as OutStateF,
           abs(fee3 - fee2) as OutStateFDiff
    from ipeds.tuitionandcosts;
quit;

/* Merge TuitionUpdate with PREIPEDSMRGD */
PROC SQL;
    CREATE TABLE PREIPEDSMRGD2 AS
    SELECT a.*, b.*
    FROM PREIPEDSMRGD a
    LEFT JOIN TuitionUpdate b
    ON a.unitid = b.unitid;
QUIT;


PROC SORT DATA=PREIPEDSMRGD2 OUT=ElifGit.FINALTABLE NODUPKEY;
    BY unitid;
RUN;

/*GLM SELECT*/

PROC GLMSELECT DATA=ElifGit.FINALTABLE;
    MODEL Rate = iclevel control cbsatype GrantRate GrantAvg PellRate
                 LoanRate LoanAvg InDistrictT InDistrictTDiff
                 InDistrictF InDistrictFDiff InStateT InStateF
                 OutStateT OutStateTDiff OutStateF OutStateFDiff
                 AvgSalary StuFacRatio
        / SELECTION=STEPWISE
          SELECT=AIC
          CHOOSE=AIC;
    STORE OUT=ElifGit.GradModel;
RUN;
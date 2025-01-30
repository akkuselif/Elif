libname IPEDS '~/IPEDS';
LIBNAME ElifGit '~/ElifGit';
options fmtsearch=(IPEDS);
ods graphics on;

/* Create initial graduation rates table */
proc sql;
   create table GradRates as
   select distinct
          enroll.unitid as unitid label="School Identifier", 
          enroll.Total as cohort label="Incoming Cohort Size",
          (grad.Total / enroll.Total) as Rate format=percentn8.2 label="Graduation Rate"
   from (select unitid, total
         from IPEDS.graduation
         where group eq "Incoming cohort (minus exclusions)"
        ) as enroll 
   inner join (select unitid, total
               from ipeds.graduation
               where group eq "Completers within 150% of normal time"
              ) as grad
   on enroll.unitid = grad.unitid;
quit;

/* Add institutional characteristics */
proc sql;
    create table RC as 
    select distinct
           g.unitid,
           g.cohort,
           g.Rate,
           c.iclevel, 
           c.control, 
           c.hloffer, 
           c.locale, 
           c.instcat, 
           c.c21enprf, 
           c.cbsatype
    from GradRates as g 
    left join ipeds.characteristics as c
    on g.unitid = c.unitid;
quit;

/* Add financial aid information */
proc sql;
    create table RCA as
    select distinct
        RC.*,
        case 
            when a.scfa2 > 0 then (a.uagrntn / a.scfa2) 
            else 0 
        end as GrantRate format=percentn8.2 
            label="Percent receiving grant aid",
        case 
            when a.scfa2 > 0 then (a.uagrntt / a.scfa2)
            else 0 
        end as GrantAvg 
            label="Average grant aid amount",
        case 
            when a.scfa2 > 0 then (a.upgrntn / a.scfa2)
            else 0 
        end as PellRate format=percentn8.2 
            label="Percent receiving Pell grants",
        case 
            when a.scfa2 > 0 then (a.ufloann / a.scfa2)
            else 0 
        end as LoanRate format=percentn8.2 
            label="Percent with federal loans",
        case 
            when a.scfa2 > 0 then (a.ufloant / a.scfa2)
            else 0 
        end as LoanAvg 
            label="Average federal loan amount"
    from RC
    left join ipeds.aid as a on RC.unitid = a.unitid;
quit;

/* Add tuition and costs information */
proc sql;
    create table RCAT as
    select distinct
        RCA.*,
        case when t.tuition1 ne t.tuition2 then 1 else 0 
        end as InDistrictT label="Has distinct in-district tuition rate",
        case when t.tuition1 ne t.tuition2 
            then abs(coalesce(t.tuition2, 0) - coalesce(t.tuition1, 0))
            else 0 
        end as InDistrictTDiff label="Difference between in-district and in-state tuition",
        case when t.fee1 ne t.fee2 then 1 else 0 
        end as InDistrictF label="Has distinct in-district fee rate",
        case when t.fee1 ne t.fee2
            then abs(coalesce(t.fee2, 0) - coalesce(t.fee1, 0))
            else 0 
        end as InDistrictFDiff label="Difference between in-district and in-state fees",
        coalesce(t.tuition2, 0) as InStateT label="In-state average tuition",
        coalesce(t.fee2, 0) as InstateF label="In-state required fees",
        case when t.tuition3 ne t.tuition2 then 1 else 0 
        end as OutStateT label="Has distinct out-of-state tuition rate",
        case when t.tuition3 ne t.tuition2
            then abs(coalesce(t.tuition3, 0) - coalesce(t.tuition2, 0))
            else 0 
        end as OutStateTDiff label="Out-of-state tuition differential",
        case when t.fee3 ne t.fee2 then 1 else 0 
        end as OutStateF label="Has distinct out-of-state fee rate",
        case when t.fee3 ne t.fee2
            then abs(coalesce(t.fee3, 0) - coalesce(t.fee2, 0))
            else 0 
        end as OutStateFDiff label="Out-of-state fee differential",
        case when t.room = 1 then 1 else 0 
        end as Housing label="Provides student housing",
        case when t.roomcap > 0 
            then a.scfa2 / t.roomcap
            else 0 
        end as DormCapRatio label="Student to Room Ratio",
        case when t.board > 0 then 1 else 0 
        end as Board label="Provides meal plan",
        coalesce(t.roomamt, 0) as RoomAmt label="Typical room charge",
        coalesce(t.boardamt, 0) as BoardAmt label="Typical board charge"
    from RCA
    left join ipeds.tuitionandcosts as t on RCA.unitid = t.unitid
    left join ipeds.aid as a on t.unitid = a.unitid;
quit;

/* Add faculty information */
proc sql;
    create table RCATS as
    select distinct
        RCAT.*,
        coalesce(s.AvgSalary, 0) as AvgSalary label="Average faculty salary",
        coalesce(s.StuFacRatio, 0) as StuFacRatio label="Student to faculty ratio"
    from RCAT 
    left join (
        select s.unitid,
               case when sum(s.sa09mct) > 0 
                    then sum(s.sa09mot) / sum(s.sa09mct)
                    else 0 
               end as AvgSalary,
               case when sum(s.sa09mct) > 0
                    then mean(a.scfa2) / sum(s.sa09mct)
                    else 0 
               end as StuFacRatio format=comma5.1
        from ipeds.salaries as s
        left join ipeds.aid as a on s.unitid = a.unitid
        group by s.unitid
    ) as s
    on RCAT.unitid = s.unitid;
quit;

/* Set up output datasets */
ods output 
    ModelInfo=work.modelInfo
    NObs=work.Obs
    SelectionSummary=work.Selection
    ParameterEstimates=work.Estimates;

/* Run stepwise regression */
proc glmselect data=work.RCATS plots=all;
    class iclevel control cbsatype board(ref='0');
    model Rate = iclevel control cbsatype 
                 GrantRate GrantAvg PellRate
                 LoanRate LoanAvg InDistrictT InDistrictTDiff
                 InDistrictF InDistrictFDiff InStateT InstateF
                 OutStateT OutStateTDiff OutStateF OutStateFDiff
                 Housing DormCapRatio Board RoomAmt BoardAmt
                 AvgSalary StuFacRatio
          / selection=stepwise
            select=AIC
            choose=AIC
            hierarchy=single;
    store out=ElifGit.GradModel;
    output out=predictions p=predicted r=residual;
run;

/* Check ModelInfo contents */
proc contents data=work.modelInfo;
run;

/* Create model summary */
proc transpose data=work.modelInfo(where=(label1 in ('Selection Method', 'Select Criterian', 'Stop Criterion', 'Choose Criterian')))
    out=work.model(drop=_name_);
    var cValue1;
    id label1;
run;

/* Print transposed model data */
proc print data=work.model;
    title "Transposed Model Information";
run;

/* Create final results table */
proc sql;
    create table work.modelResults as
    select distinct
           m.*, 
           o.NObsRead, 
           o.NObsUsed, 
           s.Step, 
           e.Parameter, 
           s.AIC as CriterionValue,
           e.Estimate, 
           e.StdErr, 
           e.StandardizedEst
    from work.model as m
    cross join work.obs as o
    inner join work.selection as s
        on 1=1
    inner join work.estimates as e
        on s.EffectEntered = scan(e.Parameter, 1, ' ')
    order by s.Step, e.Parameter;
quit;

/* Print results */
title "Model Information";
proc print data=work.modelInfo;
run;

title "Number of Observations";
proc print data=work.Obs;
run;

title "Selection Summary";
proc print data=work.Selection;
run;

title "Parameter Estimates";
proc print data=work.Estimates;
run;

title "Combined Model Results";
proc print data=work.modelResults;
run;

title;
ods graphics off;
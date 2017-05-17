	/*******************************************************************************/
	/**************           library and data base set up        *****************/
	/*******************************************************************************/

OPTIONS S=72  MISSING= ' ' NOSOURCE NOCENTER PS=9999;
DM "log; clear; ";
dm 'odsresults; clear';
libname dbo ODBC DSN=SFCC_DW UID=SFCC_DW_IR PWD=R3ad_0n!y  SCHEMA=DBO;

	/*******************************************************************************/
	/************** 			concatenating for sorting   	   *****************/
	/*******************************************************************************/
*would be able to sort through three items this way;

sort = Student_ID||''||Test||''||score

	/*******************************************************************************/
	/************** comparing two data set to find missing values  *****************/
	/*******************************************************************************/

PROC SQL;
      CREATE TABLE CA15_SIDs_missing_one_year AS
	  		SELECT DISTINCT 
       			 t1.Student_ID
                                    
					from Missing_SIDs AS t1 
							
							left Join DSCS2 As t2 
								On t1.Student_ID = t2.Student_ID
                                    
                        WHERE t2.Student_ID Is NULL
ORDER BY Student_ID;



	/*******************************************************************************/
	/*****************************  complex inquiries   ***********************/
	/*******************************************************************************/
*avoiding a right join with a wehere on left table;

proc sql;
	create table cnx_sids_Blount_test as
		select distinct t3.Term_Year, t3.Term_Name, t4.Course,t4.Course_Section,t4.Course_Credit_Hours,t4.Student_ID,t4.cnx_date
		From Blount_CNX as t3
		left join
		(select distinct t2.Term_Year, t2.Term_Name, t2.Course,t2.Course_Section,t2.Course_Credit_Hours, t1.Student_ID,t2.cnx_date
			From  Dropped_sids as t1
				inner join Blount_CNX as t2
					on t1.Term_Year = t2.Term_Year
						and t1.Term_Name = t2.Term_Name
						and t1.Course = t2.Course
						and t1.Course_Section = t2.Course_Section
				where t1.Course_Update_Status_Date_SCH= t2.cnx_Date	
		) as t4	
			
			on t3.Course = t4.Course
				and t3.Course_Section = t4.Course_Section
order by Course, Course_Section;
quit;


	/*******************************************************************************/
	/*****************************  concatentate   ***********************/
	/*******************************************************************************/

data black_male_ind_FTASF_data2;
set black_male_ind_FTASF_data;

format year_term 6.0;

year_term = cats(Term_year, Term_Number);
run;



	/*******************************************************************************/
	/*****************************  correlation matrix  ***********************/
	/*******************************************************************************/


ods select Cov PearsonCorr;
proc corr data=summary outp=sumcorr
	nomiss;
var /*Students__Affected Total_Enrollment__Credits_Cancel Percent_Students_Whose__enrollme
	Percent_Re_enrollments_that_Re_e Percentage_Students__Blount_Lost Blount_Only_Students_Who_Left*/ Percentage_of_Students_SF_Lost
	Average_Days__Course_Cancelled_P Percent_of_Credits_Recovered____ Percent_Increase_in_Credits___Dr
	Enrollment_Location_Distribution Enrollment_Location_Distributio0 Enrollment_Location_Distributio1;
run;


	/*******************************************************************************/
	/*****************************  current term inquiries   ***********************/
	/*******************************************************************************/

Proc SQL;                                                                                                                                                                    
      CREATE TABLE Sp16 AS    
	SELECT count(Student_ID) AS Students From (  
     	SELECT DISTINCT 
				t1.Term_Year, 
				t1.Term_Name, 
				t2.Student_ID
		FROM dbo.Daily_Term_Summary AS t1 

			INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

			INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

			INNER JOIN dbo.Daily_Course_Snapshot AS t3 
					ON t2.Run_Date = t3.Run_Date 
						AND t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Session_Code = t3.Session_Code 
						AND t2.Course = t3.Course 
						AND t2.Course_Section = t3.Course_Section

		WHERE (t2.Enrollment_Status_Code ^= 'D')  
			AND (t1.Term_Year = '2016') 
			AND (t1.Term_Name = 'Spring')	
			AND (t1.Run_Date = '10feb2016'd)
		
);
QUIT; *14276;


				/**************************************************/
				/*****************    data steps   ****************/
				/**************************************************/


* adding zeros on SIds;

data Gary_Fa13;
set Gary_Fa13;

a = put(Student_ID, 8.);
run;

data Gary_Fa13;
set Gary_Fa13;

Stud_ID=translate(right(a),'0',' ');

run;

*change from char to numeric and rename with same avr name;

data mm_dat2;
set mm_dat;
RACT2 = input(RACT, 4.);
drop RACT;
rename RACT2=RACT;
run;

*delete all missing values from vars;

data mm_dat4;

set mm_dat3;

if cmiss(of _all_) then delete;

run;


*new field;

data Hispanic_Data;

	format Hispanic_Overall Percent9.2;
	format Hispanic_CTE Percent9.2;

	Hispanic_Overall = &Hispanic_Sp16./14276;

	Hispanic_CTE  = &Hispanic_CTE_Sp16./&Hispanic_Sp16.;

run;


**********************************dates;

data reg2;
set reg;
format RegistrationDate YYMMDDN8.;		* formats sas date in form, N indicates no dashes, 8 tells it to have YYYY;

RegistrationDate=datepart(Reg_date); 	*date part creates a sas date from SQL date;			

drop dd date1 Reg_date;
run;*8468;


data AY11_12_Sids3;
set AY11_12_Sids2;
format date1 date.;
format (Birth_Month, 'MM');
dd=datepart(Student_Birth_Date); 	*creates a sas date (just numbers from zero date) from SQL date;
date1 = dd; 						*changes sas date to day month year;
Birth_Year = year(date1); 			*pulls out year;
Birth_Month = month(date1);
drop dd date1 Student_Birth_Date;
run;

data sa_dates ; 
	set sp15_stopped_attending_Gateway;
	dd=datepart(Stopped_Attending_Date_SCH);
	wd=datepart(Withdrew_Date_SCH);


*numbers to dates  20150201 to 2015/02/01;
data not_grad_sids4 (drop = Prog_GPA Need);
set not_grad_sids3;
Last_Date_Attended = input(put(Last_Date_Attended, 8.),YYMMDD8.);
format Last_Date_Attended YYMMDD10.;
run;


/*date1=put(dd,date9.);  for convert to day month year*/
run;

data sa_dates1 ; 
	set sa_dates;

	format days 3.0;
	sa_days=dd-20093;
	w_days=wd-20093;

	Keep Term_Year Term_Name Course sa_days w_days;

run;

DATA DATE_Stuff;
	SET DATE_Stuff;
	FORMAT Day1 date10.;
	FORMAT dd date10.;
	FORMAT dd2 DDMMYY10.;
	FORMAT dd3 WEEKDATE29.;
	FORMAT Age 5.2;
	FORMAT Text_Date $10.;
	FORMAT mm da $2.;
	FORMAT yy $4.;
	FORMAT dd4 MMDDYY10.;
		Day1 = '01jan1960'd;
		dd = SAS_DATE;
		dd2 = SAS_DATE;
		dd3 = SAS_DATE;
		Age = (dd - Day1)/365.25;
		Text_Date = "10/25/1995";
		mm = substr(Text_Date,1,2);
		da = substr(Text_Date, 4,2);
		yy = substr(Text_Date,7,4);
		dd4 = mdy(mm,da,yy);
RUN;

*deleting  and creating variables;

data Sp15_successful_data1 (Drop = rd Transaction_Number Transaction_Receipt_Date);
set Sp15_successful_data;
	
	successful = 1; *successful= 0 , means failed or withdrew, successful = 1 means passed;

run;


*flatfile;
data tests3;
set  tests2;
FORMAT RPER 3.0;
FORMAT MPER 3.0;
FORMAT WPER 3.0;
FORMAT RSAT 3.0;
FORMAT WSAT 3.0;
FORMAT MSAT 3.0;
FORMAT RACT 3.0;
FORMAT EACT 3.0;
FORMAT MACT 3.0;
FORMAT SACT 3.0;

if Test = "PER" and SECT_CD = "READING" then RPER = SCORE_VAL;
if Test = "PER" and SECT_CD = "MATH" then MPER = SCORE_VAL;
if Test = "PER" and SECT_CD = "WRITING" then WPER = SCORE_VAL;

if Test = "SAT" and SECT_CD = "CRITRDG" then RSAT = SCORE_VAL;
if Test = "SAT" and SECT_CD = "WRITING" then WSAT = SCORE_VAL;
if Test = "SAT" and SECT_CD = "MATH" then MSAT = SCORE_VAL;

if Test = "ACT" and SECT_CD = "READING" then RACT = SCORE_VAL;
if Test = "ACT" and SECT_CD = "ENGLISH" then EACT = SCORE_VAL;
if Test = "ACT" and SECT_CD = "MATH" then MACT = SCORE_VAL;
if Test = "ACT" and SECT_CD = "SCIENCE" then SACT = SCORE_VAL;


KEEP Student_ID RPER MPER WPER RSAT WSAT MSAT RACT EACT MACT SACT;
run;

proc sql;
create table tests4 as
select 			Student_ID, 
				Sum(RPER) as RPER, 
				Sum(MPER) as MPER, 
				Sum(WPER) as WPER, 
				Sum(RSAT) as RSAT, 
				Sum(WSAT) as WSAT, 
				Sum(MSAT) as MSAT, 
				Sum(RACT) as RACT, 
				Sum(EACT) as EACT, 
				Sum(MACT) as MACT, 
				Sum(SACT) as SACT 
from tests3
group by Student_ID
order by Student_ID;


*keep items from one data set that are not in the other;
*both data set must be sorted by id;
data graduated6;

merge graduated5(in=a) graduated4(in=b);
by Student_ID;
if a and not b;
run;

*queries;

data sp15_gateway_F2;

set sp15_gateway_F1;

 if Parent_Adjusted_Gross_Income_Fro < 0 then delete;
 if Parent_Adjusted_Gross_Income_Fro >= 750000 then delete;
 if Student_Income_Earned_From_Work < 0 then delete;

run;


data sp15_gateway_F2;

set sp15_gateway_F1;
 
 if Parent_Adjusted_Gross_Income_Fro <= 0 then Parent_Adjusted_Gross_Income_Fro = '';
 if Student_Income_Earned_From_Work < 0 then Student_Income_Earned_From_Work = '';

run;


data transients4 (where=(Academic_Year < '2016'));

set transients3;

	by Academic_Year  Student_ID Program_Title;
	
	if first.Student_ID then output;

run;

*using where statements;

data m_dat;

set demo (where= (Course in ('MAT1033', 'MAC1105')));

keep Student_Gender_Code Financial_Aid_Student_Flag Program_Title Dependency_Status Enrollment_Code_Description
Student_Age_At_Beginning_Of_Term FTIC_First_Time_in_College_Flag Student_Credit_Hours_For_Term GPA_All_College Earned_Hours_All_College
County Student_Income_Earned_From_Work Parent_Adjusted_Gross_Income_Fro Father_Education Mother_Education Children_yes_no RPER MPER 
WPER RSAT WSAT MSAT RACT EACT MACT SACT successful Percentile Missing;

run;

*merging data ordering and sorting;


proc sort data=Student_status_graduated;
by Stud_ID;
run;

proc sort data=Student_status_enrolled2;
by Stud_ID;
run;

proc sort data=Student_status_enrolled1;
by Stud_ID;
run;

proc sort data=gary_Fa13_2;
by Stud_ID;
run;

data Gary_Fa13_enroll_grad ;
retain Graduation_Term_Year  Term_Year Term_Name Stud_ID;
merge gary_Fa13_2 Student_status_graduated Student_status_enrolled1 Student_status_enrolled2;
by Stud_ID;
run;
quit;

proc sort  data = Gary_Fa13_enroll_grad;
by descending Graduation_Term_Year descending Term_Year descending Term_Name descending Stud_ID ;
run;


				/*********************************************************/
				/***************    decision trees       *****************/
				/********************************************************/


ods graphics on;

proc hpsplit data=data4 seed = 111;

class Attrite ethnicity gender;

model Attrite (event = 'Yes') =
	ethnicity gender GPA count years_attended;
grow entropy;
prune costcomplexity;
run;
ods graphics off;
quit;



				/*********************************************************/
				/***************       enrollment         *****************/
				/********************************************************/



SELECT  Term_Year, SUM(Spring) AS Spring, SUM(Summer) AS Summer, SUM(Fall) AS Fall

	FROM   (
		SELECT  Term_Year, 
				Most_Recent_For_Term_Flag, 
				CASE WHEN Term_Name = 'Spring' THEN Unduplicated_Student_Count_for_Term ELSE 0 END AS Spring, 

                CASE WHEN Term_Name = 'Summer' THEN Unduplicated_Student_Count_for_Term ELSE 0 END AS Summer, 

				CASE WHEN Term_Name = 'Fall' THEN Unduplicated_Student_Count_for_Term ELSE 0 END AS Fall

            FROM     dbo.Daily_Term_Summary

            WHERE   (Academic_Year > '2000') AND (Most_Recent_For_Term_Flag = 'H')) AS Tbl1
)

GROUP BY Term_Year

ORDER BY Term_Year;

 				/*********************************************************/
				/*************** ethinic queries         *****************/
				/********************************************************/

*state level;

PROC SQL;
CREATE TABLE fa_14_ethinicty AS
	SELECT DISTINCT 
			t2.SSN, Gender_CD,
			CASE WHEN Race_White_FL = 'Y' THEN 1 ELSE 0 END AS Race_White,
			CASE WHEN Race_Black_FL = 'Y' THEN 1 ELSE 0 END AS Race_Black,
			CASE WHEN Race_Asian_FL = 'Y' THEN 1 ELSE 0 END AS Race_Asian,
			CASE WHEN Race_Indian_FL = 'Y' THEN 1 ELSE 0 END AS Race_Indian,
			CASE WHEN Race_Hawaiian_FL = 'Y' THEN 1 ELSE 0 END AS Race_Hawaiian,
			CASE WHEN Ethnic_Hispanic_FL = 'Y' THEN 1 ELSE 0 END AS Race_Hispanic

	FROM dbo.SRT_SDB_Demo as t2
			
	WHERE     (t2.Term_YR = '2014') AND (t2.Term_Num_CD = '2') AND (t2.Run_CD = 'E')

order By SSN;
                                                                                                                                               
QUIT;


DATA fa_14_ethinicty2;
	SET fa_14_ethinicty;	

	Two_or_More = Race_White + Race_Black + Race_Asian + Race_Indian + Race_Hawaiian;
	Unknown = 0;

	IF Two_Or_More > 1 AND Race_Hispanic = 0 THEN
		DO;
			Ethnicity = 'Multi-Racial';
			Multi_Racial = 1;
			Race_White = 0;
			Race_Black = 0;
			Race_Asian  = 0;
			Race_Indian = 0;
			Race_Hawaiian = 0;
			Race_Hispanic = 0;
		END;
	ELSE
		Multi_Racial = 0;

	IF Race_Hispanic = 0 AND Two_Or_More = 1 THEN	/*Two_or_More = 1 means only one race */
		DO;											/*was selected by the applicant       */
			IF Race_White = 1 Then Ethnicity = 'White';
			Else If Race_Black = 1 THEN Ethnicity = 'Black';
			ELSE IF Race_Asian = 1 THEN Ethnicity = 'Asian';
			Else IF Race_Indian = 1  THEN Ethnicity = 'Native American or Alaskan Native';
			ELSE IF Race_Hawaiian = 1  THEN Ethnicity = 'Native Hawaiian or Other pacific Islander';
			/*Else IF Race_Hispanic = 1  THEN Ethnicity = 'Hispanic';*/
			ELSE Ethnicity = 'Not Reported';
		END;
	ELSE
		IF Race_Hispanic = 0 AND Multi_Racial = 0 THEN
			DO;
				Ethnicity = 'Not Reported';
				Unknown = 1;
			END;
		ELSE
			Unknown = 0;

	IF Race_Hispanic = 1 THEN
		Ethnicity = 'Hispanic or Latino';

	DROP Two_or_More Unknown Multi_Racial Race_White Race_Black Race_Asian Race_Indian Race_Hawaiian Race_Hispanic;

Run;



*non-state db;

PROC SQL;
CREATE TABLE center_ethinicty AS
	SELECT DISTINCT 
			t1.Student_ID, 
			CASE WHEN Race_White_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_White,
			CASE WHEN Race_Black_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_Black,
			CASE WHEN Race_Asian_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_Asian,
			CASE WHEN Race_Indian_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_Indian,
			CASE WHEN Race_Hawaiian_FLAG= 'Y' THEN 1 ELSE 0 END AS Race_Hawaiian,
			CASE WHEN Ethnic_Hispanic_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_Hispanic

	from center_race2 as t1 
	inner join dbo.SFCC_ID_Lookup as t2
		on t1.Student_ID = t2.SFCC_ID

;
                                                                                                                                               
QUIT;

DATA center_ethinicty2;
SET center_ethinicty;	

format Ethnicity $18.0;

Two_or_More = Race_White + Race_Black + Race_Asian + Race_Indian + Race_Hawaiian;
	Unknown = 0;

IF Two_Or_More > 1 AND Race_Hispanic = 0 THEN
		DO;
			Ethnicity = 'Multi-Racial';
			Multi_Racial = 1;
			Race_White = 0;
			Race_Black = 0;
			Race_Asian  = 0;
			Race_Indian = 0;
			Race_Hawaiian = 0;
			Race_Hispanic = 0;
END;
	ELSE
		Multi_Racial = 0;

IF Race_Hispanic = 0 AND Two_Or_More = 1 THEN	/*Two_or_More = 1 means only one race */
		DO;											/*was selected by the applicant       */
			IF Race_White = 1 Then Ethnicity = 'White';
			Else If Race_Black = 1 THEN Ethnicity = 'Black';
			ELSE IF Race_Asian = 1 THEN Ethnicity = 'Asian';
			Else IF Race_Indian = 1  THEN Ethnicity = 'Native American or Alaskan Native';
			ELSE IF Race_Hawaiian = 1  THEN Ethnicity = 'Native Hawaiian or Other pacific Islander';
			/*Else IF Race_Hispanic = 1  THEN Ethnicity = 'Hispanic';*/
			ELSE Ethnicity = 'Not Reported';
END;
	ELSE
		IF Race_Hispanic = 0 AND Multi_Racial = 0 THEN
			DO;
				Ethnicity = 'Not Reported';
				Unknown = 1;
END;
		ELSE
			Unknown = 0;

IF Race_Hispanic = 1 THEN
		Ethnicity = 'Hispanic or Latino';

DROP Two_or_More Unknown Multi_Racial Race_White Race_Black Race_Asian Race_Indian Race_Hawaiian Race_Hispanic;

Run;
				/*********************************************************/
				/*************** exploring a dataset    *****************/
				/********************************************************/

proc contents data = m_dat;

run;

proc means data = m_dat;

run;

proc univariate data = m_dat;

run;

 


				/*********************************************************/
				/***************       exporting         *****************/
				/********************************************************/

PROC EXPORT DATA=transients
    OUTFILE="S:\Reports\common\Data Request\Programs\William\transients\transients_2012_2015.xlsx"
    DBMS=EXCEL2010 REPLACE;
   	SHEET="sheet1";
RUN;


				/*********************************************************/
				/***************        grades           *****************/
				/********************************************************/
*by course;

PROC SQL;
      CREATE TABLE sp15_stopped_attending_Gateway AS           
 
 
            SELECT DISTINCT 
                                    Term_Year, 
                                    Term_Name,
									Course,
									Student_ID,
									Stopped_Attending_Date_SCH,
									Withdrew_Date_SCH
                                   
									
                        FROM dbo.Student_Course_History 

												
						WHERE ((Institution_FICE_Code_SCH = '0001519') 
							AND (Enrollment_Status_Code_SCH <> 'D') 
                           	AND (Term_Year = '2015') 
							And (Term_Name = 'Spring') 
							AND (Course in ('MAC1105', 'ENC1101', 'MAT1033'))
							And (Course_Attempted_SFCC = 1)And (Session_Code <> 'B' )And (Session_Code <> 'A' ))
					
 					 		AND (Course_Grade_SCH IN ('D+', 'D', 'F', 'W'))	
							 
           
ORDER BY Term_Year, Term_Name;




				/*********************************************************/
				/***************        graphs          *****************/
				/********************************************************/



* additional manipulations outside the plot procedure

title1 f='Times New Roman' c=blue h =2 'Daily verse weekly'

footnote1 f=simple j-l 'source: wtc 2/15/2015'   
;

*histograms;

title "histogram of withdrawal dates by days since semester start";
proc sgplot data = sa_dates1;
histogram w_days /scale = count ;
run;
title;


*histogram panel;

proc sgpanel data =sa_dates1;
	
  	title "stopped attending by days after semester start";
 

  	panelby Course / spacing=5 novarname;
 

 	histogram sa_days;    *add / scale = count to change from percentage;
	
run;

				/*********************************************************/
				/******************   calculating GPA    *****************/
				/********************************************************/


/* SF cum gpa = gpa for SF no other college work, no Voc, but includes prep courses*/
/* if want to include Voc then remove V, to do deg only then add degree field*/
/*if want to remove dev ed class use substr*/
/* college courses are P*/
/* note grade forgiveness in effect*/
PROC SQL;
      CREATE TABLE gpa AS          
	  	
 			
            SELECT  
                   Student_ID,Course, Course_Section, Course_Grade_Points_SCH, 	Student_Credit_Hour_equivalent				
									
                        FROM dbo.Student_Course_History 	
                  
                        WHERE Institution_FICE_Code_SCH = '0001519'
                              AND Enrollment_Status_Code_SCH not in ('W', 'D') 
								
							/*and substr(Course, 4,1) <> '0' 
                              /*and (((substr(Course, 4,1) <> '0' ) and (Course_Type_Code_SCH <> 'V')) or 
												((substr(Course, 4,1) = '0' ) and (Course_Type_Code_SCH = 'V')))*/
							  and Course_Type_Code_SCH not in ('S', 'V')  
/*v = vocational, P = college level, c = developmentl, s = adult ed*, b = , o = informational courses*/
							  and Audit_Flag_SCH <> 'A'
							  and Student_Id in (select Student_Id from data)
                 
ORDER BY Student_ID, Course, Course_grade_points_sch desc;

QUIT;

data gpa2a;
set gpa;
by student_id course;
if first.course then output;

run; 

proc sql;
	create table gpa1 as
		select Student_ID, Course, Course_Section, Course_Grade_Points_SCH, Student_Credit_Hour_equivalent, 
				sum(Student_Credit_Hour_equivalent) as total_credits

		from gpa2a
group by student_id;
quit;

data gpa2;
set gpa1;

format grade_points 4.3;
grade_points  = course_grade_points_sch*student_credit_hour_equivalent ;

run;

proc sql;
	create table gpa3 as
	select distinct Student_ID, sum(grade_points) as total_grade_points,  total_credits
	from gpa2
group by student_id
order by student_id;
quit;

data gpa4;

set gpa3;

format GPA 4.2;

GPA = total_grade_points/total_credits;

run;

				/*********************************************************/
				/******************   importing         *****************/
				/********************************************************/


PROC IMPORT DATAFILE= "S:\Reports\common\Data Request\Programs\William\sas_withdraw_periods_CA_IA_ENC\Final_Data\Ca_IA_Enc_SIDs_missing_Sp15.xlsx"	
OUT=Ca_IA_Enc_SIDs_missing_Sp15
	 DBMS=EXCEL2010 REPLACE;
run;

*specify which row is header and which row is observation;

PROC IMPORT DATAFILE= "S:\Reports\common\Data Request\Programs\William\ad hoc\RFTT\final file\R434_4_28_2016_RFTT\primary2.xlsx"	
OUT=primary2 DBMS=EXCEL2010 REPLACE;
	Range = "sheet1$B3:J5759";
	GETNAMES= yes;
	DBDSOPTS = 'firstobs =1';
run;


*for csv files:

PROC IMPORT DATAFILE= "S:\Reports\common\Data Request\Programs\William\sas_withdraw_periods_CA_IA_ENC\Final_Code\final_by_course\write up\missing_math_sids__best_model_scorecard_sp16.csv"	
OUT=sp16_preds DBMS=csv out=data;

getnames=yes;
datarow=2;
run;


				/*********************************************************/
				/******************   libraries         *****************/
				/********************************************************/
*creates a library called sasout in my file;
OPTIONS S=72  MISSING= ' ' NOSOURCE NOCENTER PS=9999;

DM "log; clear; ";
dm 'odsresults; clear';


libname dbo ODBC DSN=SFCC_DW UID=SFCC_DW_IR PWD=R3ad_0n!y  SCHEMA=DBO;


%let path = S:/Reports/common/Data Request/Programs/William/sas_withdraw_periods_CA_IA_ENC/Final_Code/final_by_course/sas_out;

libname sas_out "&path";


*second method;

libname sasout "S:/Reports/common/Data Request/Programs/William/sas_withdraw_periods_CA_IA_ENC/Final_Code/final_by_course";

run;


*see a table in it;

proc print data=sas_out.sp15_demo_data;
run;

*erase a library;
libname sasout clear;

*to view contents of a library
*data = "library name", add after _all_ a space then nods if want to eliminate all information;

proc contents data = sas_out._ALL_;
run;

proc print data = sasout.sp15_demo_dat;
run;

				/*********************************************************/
				/******************  looping through data ****************/
				/********************************************************/

DATA work.Dataset_2;
      SET work.Dataset1;
      
      %LET Student = Student_ID;
      %PUT &Student.;
      
      If substr(Gtwy_Course,1,3) = 'MAT' AND substr(Dev_Ed_Course,1,3) ^= 'MAT' THEN

            CALL EXECUTE("PROC SQL; 
DELETE * 
FROM work.Fall_Enrollment_a 
WHERE Student_ID = '" || &Student || "' 
    AND substr(Gtwy_Course,1,3) = 'MAT' 
    AND substr(Dev_Ed_Course,1,3) ^= 'MAT'; 
                          QUIT;");
RUN;


				/*********************************************************/
				/******************   maximums          *****************/
				/********************************************************/

proc sort data=sp15_gateway_F3 ;by Student_ID descending rd; run;

data sp15_gateway_F4;
set sp15_gateway_F3;
by Student_ID;

if First.Student_ID then output;

run;

				/***********************************************************************************/
				/***************   merge multiple rows by sid in one table        ******************/
				/***********************************************************************************/


data enr4;
update enr3(obs=0) enr3;
by Student_ID;
run;

				/*********************************************************/
				/***************   missing values        *****************/
				/********************************************************/

*proc stdize;

proc stdize data=sp15_CA_ENC_IA_Demo2 reponly missing=0 out=sp15_gateway_success_Demo2_clean;
var Student_Income_Earned_From_Work;
run;

				
				/*********************************************************/
				/***************   past term inquiries   *****************/
				/********************************************************/


Proc SQL;                                                                                                                                                                    
      CREATE TABLE COURSE_DATA_Prev AS                                                                                                                                      
                                                                                                                                                                            
     	SELECT DISTINCT 
				t1.Term_Year, 
				t1.Term_Name, 
				t2.Student_ID,
				t4.Program_of_Study_Code,
				t4.Program_Title,
				t4.Degree,
				t4.Program_Admission_Pending, 
                t4.Program_Admission_Year,
				t4.Student_Gender_Code,
				t4.Student_Race_Letter_Code

		FROM dbo.Daily_Term_Summary AS t1 

				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

		WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
			AND (t3.Institution_FICE_Code_SCH = '0001519') 
			AND (t2.Enrollment_Status_Code <> 'D') 
			AND (t3.Enrollment_Status_Code_SCH <> 'D') 
			/*AND (t1.Term_Year = '2009' OR t1.Term_Year = '2010' OR t1.Term_Year = '2011' OR t1.Term_Year = '2012' OR t1.Term_Year = '2013') */
			AND (t1.Term_Year = '2014' )
			AND (t1.Term_Name = 'Summer')
			/*AND t4.Program_of_Study_Code = '2610'*/
			/*AND t4.Degree IN ('AA', 'AS', 'AAS')*/

ORDER BY Term_Year, Term_Name;
QUIT;

			

				
				/*********************************************************/
				/******************   printing to pdf   *****************/
				/********************************************************/



ODS Listing Close;
ODS PDF File = "S:\Reports\common\Data Request\Programs\William\sas_withdraw_periods_CA_IA_ENC\Final_Code\stopped_attending_Charts.pdf";


footnote1 height =1 "source: william clarke 2/24/16 from sa_dates1 generated by Sp15_stopped_attending_histogram_sas";

**********graphical code here;

ODS PDF Close;
ODS Listing;

				/*********************************************************/
				/******************   race and gender      *****************/
				/********************************************************/
PROC SQL;
CREATE TABLE ethnicity AS
	SELECT DISTINCT 
			t1.Student_ID, 
			CASE WHEN Race_White_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_White,
			CASE WHEN Race_Black_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_Black,
			CASE WHEN Race_Asian_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_Asian,
			CASE WHEN Race_Indian_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_Indian,
			CASE WHEN Race_Hawaiian_FLAG= 'Y' THEN 1 ELSE 0 END AS Race_Hawaiian,
			CASE WHEN Ethnic_Hispanic_FLAG = 'Y' THEN 1 ELSE 0 END AS Race_Hispanic

	from counselling_data as t1 
	inner join dbo.SFCC_ID_Lookup as t2
		on t1.Student_ID = t2.SFCC_ID
;                                                                                                                                           
QUIT;
*26438;

DATA ethnicity2;
SET ethnicity;	
format Ethnicity $18.0;

Two_or_More = Race_White + Race_Black + Race_Asian + Race_Indian + Race_Hawaiian;
	Unknown = 0;
IF Two_Or_More > 1 AND Race_Hispanic = 0 THEN
		DO;
			Ethnicity = 'Multi-Racial';
			Multi_Racial = 1;
			Race_White = 0;
			Race_Black = 0;
			Race_Asian  = 0;
			Race_Indian = 0;
			Race_Hawaiian = 0;
			Race_Hispanic = 0;
END;
	ELSE
		Multi_Racial = 0;

IF Race_Hispanic = 0 AND Two_Or_More = 1 THEN	/*Two_or_More = 1 means only one race */
		DO;											/*was selected by the applicant       */
			IF Race_White = 1 Then Ethnicity = 'White';
			Else If Race_Black = 1 THEN Ethnicity = 'Black';
			ELSE IF Race_Asian = 1 THEN Ethnicity = 'Asian';
			Else IF Race_Indian = 1  THEN Ethnicity = 'Native American or Alaskan Native';
			ELSE IF Race_Hawaiian = 1  THEN Ethnicity = 'Native Hawaiian or Other pacific Islander';
			/*Else IF Race_Hispanic = 1  THEN Ethnicity = 'Hispanic';*/
			ELSE Ethnicity = 'Not Reported';
END;
	ELSE
		IF Race_Hispanic = 0 AND Multi_Racial = 0 THEN
			DO;
				Ethnicity = 'Not Reported';
				Unknown = 1;
END;
		ELSE
			Unknown = 0;

IF Race_Hispanic = 1 THEN
		Ethnicity = 'Hispanic or Latino';

DROP Two_or_More Unknown Multi_Racial Race_White Race_Black Race_Asian Race_Indian Race_Hawaiian Race_Hispanic;

Run;
*509;

*this query is done by site and college credit courses;
Proc SQL;                                                                                                                                                                    
      CREATE TABLE center_race AS                                                                                                                                      
			SELECT Term_Year, Term_Name, Sum(B) AS Black, sum(W) AS White, sum(H) AS Hispanic, sum(A) AS Asian,
sum(I) AS American_Indian, sum(X) AS Not_reported, Sum(M) as Male, Sum(F) as Female, Sum(O) as Other 

			from ( 
     			SELECT  
					t1.Term_Year, 
					t1.Term_Name, 
					t2.Student_ID,
					case when t4.student_race_letter_code = 'B' then 1 else 0 end as B,
					case when t4.student_race_letter_code = 'W' then 1 else 0 end as W,
					case when t4.student_race_letter_code = 'H' then 1 else 0 end as H,
					case when t4.student_race_letter_code = 'A' then 1 else 0 end as A,
					case when t4.student_race_letter_code = 'H' then 1 else 0 end as H,
					case when t4.student_race_letter_code = 'I' then 1 else 0 end as I,
					case when t4.student_race_letter_code = 'X' then 1 else 0 end as X,
					case when t4.Student_Gender_Code = 'M' then 1 else 0 end as M,
					case when t4.Student_Gender_Code = 'F' then 1 else 0 end as F,
					case when t4.Student_Gender_Code = 'O' then 1 else 0 end as O
				

			FROM dbo.Daily_Term_Summary AS t1 
				INNER JOIN dbo.Daily_Student_Course_Snapshot AS t2 
					ON t1.Run_Date = t2.Run_Date 
						AND t1.Term_Year = t2.Term_Year 
						AND t1.Term_Number = t2.Term_Number 

				INNER JOIN dbo.Daily_Student_Info_Snapshot AS t4
					ON t2.Run_Date = t4.Run_Date 
						AND t2.Student_ID = t4.Student_ID 

				LEFT OUTER JOIN dbo.Student_Course_History AS t3 
					ON t2.Term_Year = t3.Term_Year 
						AND t2.Term_Number = t3.Term_Number 
						AND t2.Student_ID = t3.Student_ID 
						AND t2.Course = t3.original_course_sch /*... ITS update as of 9/26/2013 This was t3.course*/
						AND t2.Course_Section = t3.Course_Section

				Inner Join dbo.Daily_Course_Snapshot as t5
					on t1.Run_date = t5.Run_date 
						and t2.Course = t5.Course
						and t2.Course_Section = t5.Course_Section

			WHERE (t1.Most_Recent_For_Term_Flag = 'H') 
				AND (t3.Institution_FICE_Code_SCH = '0001519') 
				AND (t2.Enrollment_Status_Code <> 'D') 
				AND (t3.Enrollment_Status_Code_SCH <> 'D') 
				AND (t1.Term_Year = &year. )

				and t5.Site_Where_Course_Meets = &center.

				and t5.Course_type_code in ('P', 'O')  /*college credit*/
				/*and (t5.Course_type_code in ('V') and t4.Program_of_Study_Code = '4100')*/	/*adult ed*/
				/*and t5.Course_type_code in ('C')*/	/*academic resources*/
)
GROUP BY t1.Term_Year, t1.Term_Name
ORDER BY t1.Term_Year, t1.Term_Name;
QUIT;


				/*********************************************************/
				/******************   regression      *****************/
				/********************************************************/

ods graphics on;
proc reg;
model Post_GPA = SLS_Grade / NOINT;  /* removes y intercept*/
run;
ods graphics off;

/* creates a quadrsatic variable* for ploynomial regression*/
ods graphics on;
data sls_dat_clean3;
set sls_dat_clean2;
SLS_Gradesq= SLS_Grade*SLS_Grade;
run;

/*polynomial regression*/
ods graphics on;
proc reg data = sls_dat_clean3 plots=ResidualByPredicted ;
var SLS_Gradesq;
model Post_GPA = SLS_Grade / r clm cli;
run;
add SLS_Gradesq;
print;
run;
ods graphics off;
quit;


				/*********************************************************/
				/******************   scatterplots      *****************/
				/********************************************************/

ods graphics on;
proc corr data=summary nomiss plots = scatter;
var Average_Days__Course_Cancelled_P Percentage_Students__Blount_Lost;
run;
ods graphics off;




				/*********************************************************/
				/******************   sorts             *****************/
				/********************************************************/

proc sort data=sp15_gateway_F3 ;by Student_ID descending rd; run;


				/*********************************************************/
				/******************   stats              *****************/
				/********************************************************/


title "full data set";
proc Univariate data = Sp15_successful_data plot normal;
run;
title;


Title "FULL Sp15 Successful GPA Financial Demo Summary Means";

proc means data=Sp15_successful_data  n Mean STD Median Missing NMISS;

  	var Student_Age_At_Beginning_Of_Term GPA_All_College Student_Credit_Hours_For_Term Earned_Hours_All_College Percentile
		Student_Income_Earned_From_Work Parent_Adjusted_Gross_Income_Fro Children_yes_no Legal_Dependents_yes_no
		Father_Education Mother_Education ;
 run;

Title;



Title "Partial Sp15 Successful by Percentile  Demo Summary Means";

proc means data=Sp15_successful_data  (where=(Percentile > 0)) Mean STD Median missing NMISS;
 
 	var  Student_Age_At_Beginning_Of_Term GPA_All_College Student_Credit_Hours_For_Term Earned_Hours_All_College Percentile
		Student_Income_Earned_From_Work Parent_Adjusted_Gross_Income_Fro Children_yes_no Legal_Dependents_yes_no
		Father_Education Mother_Education ;
 run;



Title "Sp15 Successful Financial Demo Frequencies";
proc freq data=Sp15_successful_data;
	tables Have_Children_You_Support Have_Legal_Dependents_Other_Than Veteran_Of_US_Armed_Forces HS_Diploma_Or_GED_Received;
run;

Title;



				/*********************************************************/
				/******************   substrings        *****************/
				/********************************************************/


Student_ID=substr(SID,1,9);

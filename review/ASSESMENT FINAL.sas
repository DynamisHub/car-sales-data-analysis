/* Define the PDF output path */

%let pdf_output = '/home/u63777748/sasuser.v94/assignment part2/part2.2report.pdf';

/* Open ODS PDF destination */
ods pdf file="&pdf_output";


/* Data Import */
proc import datafile="/home/u63777748/sasuser.v94/assignment part2/part2.1/Car_Sales.csv" 
    out=work.CarSales
    dbms=csv
    replace;
    delimiter=';';
    getnames=yes;
run;


/* Sorting Data and Removing Duplicates */
proc sort data=work.CarSales nodupkey;
    by Car_id;
run;

/* Checking Data Content */
proc contents data=work.CarSales position VARNUM;
run; 

/* Checking for null values */ 
proc sql;
   select 
       count(*) as Total_Rows,
       count(Car_id) as Car_id_Non_Missing, (count(*) - count(Car_id)) as Car_id_Missing,
       count(Date) as Date_Non_Missing, (count(*) - count(Date)) as Date_Missing,
       count(Customer_Name) as Customer_Name_Non_Missing, (count(*) - count(Customer_Name)) as Customer_Name_Missing,
       count(Gender) as Gender_Non_Missing, (count(*) - count(Gender)) as Gender_Missing,
       count(Annual_Income) as Annual_Income_Non_Missing, (count(*) - count(Annual_Income)) as Annual_Income_Missing,
       count(Dealer_Name) as Dealer_Name_Non_Missing, (count(*) - count(Dealer_Name)) as Dealer_Name_Missing,
       count(Company) as Company_Non_Missing, (count(*) - count(Company)) as Company_Missing,
       count(Model) as Model_Non_Missing, (count(*) - count(Model)) as Model_Missing,
       count(Engine) as Engine_Non_Missing, (count(*) - count(Engine)) as Engine_Missing,
       count(Transmission) as Transmission_Non_Missing, (count(*) - count(Transmission)) as Transmission_Missing,
       count(Color) as Color_Non_Missing, (count(*) - count(Color)) as Color_Missing,
       count(Price) as Price_Non_Missing, (count(*) - count(Price)) as Price_Missing,
       count(Dealer_No) as Dealer_No_Non_Missing, (count(*) - count(Dealer_No)) as Dealer_No_Missing,
       count(Phone) as Phone_Non_Missing, (count(*) - count(Phone)) as Phone_Missing,
       count(Dealer_Region) as Dealer_Region_Non_Missing, (count(*) - count(Dealer_Region)) as Dealer_Region_Missing
   from work.CarSales;
quit;

/* Formating Data */
proc print data=work.CarSales(obs=10);
           format Price Annual_Income dollar12.2;
           title 'The First 10 Cars';
run;

/* Creating New Columns Price_Category Gender_dummy */
data work.CarSales;
    set work.CarSales;
    /* Creating a new column Price_Category */
    if Price < 20000 then Price_Category='Low';
    else if Price >= 20000 and Price < 50000 then Price_Category='Medium';
    else Price_Category='High';
run;

proc print data=work.CarSales(obs=100) ;
           var Price_Category Price Gender Gender_dummy;
    title 'Price and Gender Category';
run;

/* Macro Automation */

%let plot_type = BOXPLOT;  

%macro generate_plot(plot_type);
    %if %upcase(&plot_type) = HISTOGRAM %then %do;
        proc sgplot data=work.CarSales;
            histogram Price;
            xaxis label='Price';
            yaxis label='Frequency';
            title 'Histogram of Car Prices';
        run;
    %end;
    %else %if %upcase(&plot_type) = BOXPLOT %then %do;
        proc sgplot data=work.CarSales;
            vbox Price / category=Price_Category; 
            xaxis label='Price Category';
            yaxis label='Price';
            title 'Boxplot of Car Prices by Category';
run;
    %end;
    %else %do;
        %put ERROR: The value &plot_type. is not a valid plot type. Please specify 'histogram', 'boxplot', or 'series';
    %end;
%mend generate_plot;

%generate_plot(&plot_type); 

/* Delete outliers */

proc univariate data=work.CarSales noprint;
    var Price;
    output out=work.Quartiles pctlpre=P_ pctlpts=25 75;
run;

data work.Quartiles;
    set work.Quartiles;
    call symput('LowerBound', P_25 - 1.5 * (P_75 - P_25));
    call symput('UpperBound', P_75 + 1.5 * (P_75 - P_25));
run;

%put &LowerBound &UpperBound;

data work.CarSales;
    set work.CarSales;
    if Price >= &LowerBound and Price <= &UpperBound;
run;


proc sgplot data=work.CarSales;
            histogram Price;
            xaxis label='Price';
            yaxis label='Frequency';
            title 'Histogram of Car Prices Without Outliers';
run;

/* What is the average price and average annual income? */
proc means data=work.CarSales N mean min max  ;
    var Price Annual_Income;
    title 'Basic Statistics for Price and Annual_Income';
run;

/* Are there significant differences in Annual Income and Price among the different clustering groups? */
proc fastclus data=work.CarSales maxclusters=3 out=ClusterResults ;
    var Price Annual_Income;
    title 'Clustering Results Based on Price and Annoual_Income';
run;

proc print data=ClusterResults (obs=5);
run;

proc sgplot data=ClusterResults;
   scatter  x=Price y=Annual_Income / group=CLUSTER markerattrs=(symbol=circlefilled)
        datalabel=CLUSTER;
    xaxis label='Price ($)';
    yaxis label='Income ($)';
    title 'Scatter Plot of Clustering Results Based on Price and Annual Income';
run;

/* How are cars distributed across different price categories and what is the frequency of each category? */
proc freq data=work.CarSales;
    tables Price_Category;
    title 'Frequency of Price Categories';
run;

proc sgplot data=work.CarSales;
    vbar Price_Category/stat=freq group=Price_Category;
    styleattrs datacolors=(blue green red);
    xaxis label='Price Category';
    yaxis label='Number of Cars';
    title 'Distribution of Cars Across Price Categories';
run;

/*Is there a statistically significant difference in the average car prices between genders? */
proc ttest data=work.CarSales;
    class Gender;
    var Price;
    title "T-Test for Car Prices by Gender";
run;

/*Is there a statistically significant difference in the average prices of cars with manual transmission compared to cars with automatic transmission? */
proc ttest data=work.CarSales;
    class Transmission;
    var Price;
    title "T-Test for Car Prices by Transmission";
run;

/* How do gender and transmission type, as well as their interaction, affect car prices? */
proc anova data=work.CarSales;
    class Gender Transmission ;
    model Price = Gender Transmission Gender*Transmission;
    title "ANOVA for Car Prices by Gender and Transmission";
run;

proc means data=work.CarSales noprint;
    class Gender Transmission;
    var Price;
    output out=means_data mean=Mean_Price;
run;


proc sgplot data=means_data;
    series x=Transmission y=Mean_Price / group=Gender markers;
    xaxis label='Transmission Type';
    yaxis label='Average Car Price ($)';
    title 'Interaction of Gender and Transmission Type on Car Prices';
run;

/*How do car prices vary across different companies? */
proc means data=work.CarSales noprint;
    class Company;
    var Price;
    output out=mean_prices mean=MeanPrice;
run;
proc sgplot data=mean_prices;
    heatmap x=Company y=MeanPrice / colormodel=(blue cyan green yellow orange red)
        colorresponse=MeanPrice
        name='heatmap1';
    xaxis label='Company';
    yaxis label='Average Car Price ($)';
    title 'Heatmap of Average Car Prices by Company';
run;

/* Close ODS PDF destination */
ods pdf close;

/* Εξαγωγή του τροποποιημένου dataset σε Excel */
proc export data=work.CarSales
    outfile="/home/u63777748/sasuser.v94/assignment part2/part2.1/Modified_Car_Sales.xlsx"
    dbms=xlsx
    replace;
run;



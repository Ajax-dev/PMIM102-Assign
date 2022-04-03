# PMIM102J Project - 963906

The respective README.md for the project for Pete Arnold and Dan for Scientific Computing in Healthcare. This project was completed to gain a greater knowledge on the language R and PostGreSQL and PgAdmin4, the purpose of this was to manipulate large quantities of data and perform some kinds of analysis in the sphere of medicine. 

The first task was to perform analysis on diabetes rates in Wales and from there compare Insulin vs Metformin (assuming these are 2 common diabetes medications) and if the prescription of these was statistically significant in the year 2015. 
As displayed on the R console in R studio we can definitely see a statistical significance in both of these as the respective p-values are very close to 0. This makes sense as you'd hope that more people with diabetes at a practice causes a greater increase in the prescription of relative medication.

The 2nd task was to find something interesting of our own and from there continue and attempt open-ended analysis to prove a point. My decision was to run a comparison on contraceptives vs depression, although the data is anonymised in a way that we can't see percentage of women vs men (which would have been very useful) this still proved effective as there was a statistical significance in the relationship between contraceptives prescribed and rate of depression.

## Installation

- Install R Studio.
- If needs be go to R package manager online and install: `tidyverse, crayon, GetoptLong`
- The dataset can't be included on here but for installation a zip file will be included


## Usage

Open and highlight the whole file **963906-project.R** and run (using `Ctrl+Enter`), you will have to enter your password for your PostgresSQL database, this would have been set up on PgAdmin by you.

## Functions
- `check_qof(userInput, inputResultGP, inputResultQOF)` - parameters `inputResult*` are from the respective tables and assessing validity of user input, whether the value input was present in both *gp_data_up_to_2015* & *qof_achievement* respectively.
- `contraceptives_wales(walesDepression, userInput)` - parameters taken in are `userInput` of a practice and a dataframe returned from a query `walesDepression` which takes all depression records from welsh practices. This function then prints a t-test showing statistical significance between depression and contraceptives prescribed.
- `db_list_columns(connectionName, tableName)` - lists columns from a specific table in database
- `dep_dot_plot(merged, userInput)` - plots the dot plot of depression vs contraceptives prescribed, highlighting the `userInput`.
- `dep_histo_plot(merged)` - plots a stacked histogram of contraceptive prescription (red) vs depression (black) per practice.
- `get_avg_spend(userInput)` - gets the average spend, calculates the average spend on medication monthly across wales and then next to that displays average per month on the practice from `userInput`.
- `get_diabetes(con, practiceid)` - gets diabetes value for specific `practiceid` returns this query as a dataframe.
- `get_medicine(con, chemCode)` - gets medicine prescribed and all other medicine that is not `chemCode` as a dataframe and returns both of these in a large joint query.
- `get_medicine_prescribed(con, chemCode)` - as above but earlier version of function, slightly faster as just returns medicine prescribed with a given `chemCode` per practice across Wales.
- `get_mental_health(con, practiceid)` - returns dataframe with anything to do with mental health per practice returned.
- `get_outcode(con, practiceid)` - returns the outward code of a postcode (this is the first part of a UK postcode before the space).
- `get_practices(con, column, table)` - a function used solely by two constants, simply returns a dataframe of all practices either within *qof_achievement* or *gp_data_up_to_2015*.
- `get_prescribed_without_medicine(con, chemCode)` - unintuitively named but similar to above , slightly faster as returns all medicine NOT CONTAINING `chemCode` per practice across Wales.
- `get_wales_diabetes(con)` - queries the *qof_achievement* for all diabetes, that is indicator `DM001`.
- `graph_menu(userInput, numPatients)` - a function that allows text based navigation of the graphs for diabetes related analysis.
- `graph_menu_depression(userInput, merged)` - a function like the above that is for depression related analysis.
- `home()` - the overarching function that everything stems from for user navigation.
- `insulin_ttest(userInput)` - prints out the values of t-tests for insulin vs diabetes and metformin vs diabetes.
- `loop_input(userInput)` - loops user input until correct value entered or exit condition ("q" or "Q") is met.
- `num_of_patients_sum_gp(con, input)` - a deprecated function no longer used but left in for my own learning, was an attempt at data manipulation and guessing num of patients. DEPRECATED AS RETURNED AN INCORRECT VALUE.
- `num_of_patients_sum_qof(con, input)` - the actual used function for getting total number of patients, achieved from *qof_achievement* `field4` column which is the denominator of patients, the max of the respective practiceid (input) was taken for this.
- `open_analysis_part_2(userInput)` - begins the analysis revolving around depression and contraceptive prescription.
- `search_df_practice(con, df_name, input)` - runs SQL query to get all rows that contain the `input` which in this case would be practiceid. Not scalable as relies on there being a column present called *practiceid*.
- `search_practices_from_outcode(con, outcode)` - gets all practices with the respective outcode.
- `user_input_practice()` - function that prints all practices if "*P*" is entered and quits if "*Q*" is entered.
- `visualise_diab_box(userInput)` - visualises the diabetes box and whisker plot with a vertical red line showing the user selected practice.
- `visualise_dot_plot(userInput)` - visualises the dot plot for diabetes with a highlighted red dot for the user selected practice.
- `visualise_spend(userInput, numPatients)` - histogram visualising total average spend on medication per patient at each practice that has the same outward code as the userInput practiceid.

## License
[MIT](https://choosealicense.com/licenses/mit/)
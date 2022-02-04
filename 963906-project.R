# -----------------------------------------------------------
# 963906-project.R
# Assignment_Wales_Data.Rproj
# Version 1 - 04/02/2022
# Alex Jones
## This file is for the PMIM102J assignment for Scientific 
## Computing In Healthcare, it will make use of R and SQL
## to understand large datasets regarding health data in Wales
## and gain various insights on this data based on user inputs
# -----------------------------------------------------------

# ----------------------The Task-------------------------------------
# - allow user to select a practice
#### - report if practice has medication info available
#### - report if qof data available
#### - if there's both then show: number of patients, average monthly spend
#
#
#
#
#
# -------------------------------------------------------------------

# -----------------------------IMPORTS------------------------------------------
library(tidyverse) # for tidying up the datasets
library(crayon) # to change colours in the terminal for readability
library(GetoptLong);
require("RPostgreSQL") # require is the same as library but only throws a warning, not an error

## \014 clears the console
## \012 is a newline
cat(bgGreen("\014\nPMIM102J Assignment - 963906\n")
    %+% green("---------------------------------------------------------------\n"))

# -----------------------------SET CONSTANTS------------------------------------


#Specify what driver is needed to connect to the database.
DRV <- dbDriver("PostgreSQL");
DB_NAME = "gp_practice_data" # edit this if your database is different in PostgreSQL
DB_PORT = 5432 # edit this if using a different port

# -----------------------------DATABASE-----------------------------------------
connect <- dbConnect(DRV, dbname = DB_NAME, 
                     host = "localhost", port = DB_PORT,
                     user = "postgres" , password = rstudioapi::askForPassword());

## If on windows and trouble connecting, in PgAdmin right click your postgre version
## in comments it'll tell you where data is stored
## navigate to there and then in data open pg_hba.conf
## scroll to the bottom and change local, ipv4, ipv6 EOL (end of line) from
## scram-sha-256 to trust

dbListTables(connect)

db_list_columns <- function(connection_name, table_name) {
  query <- qq("
              select
                column_name,
                ordinal_position,
                data_type,
                character_maximum_length,
                numeric_precision
              from INFORMATION_SCHEMA.COLUMNS
                where table_schema = 'public'
                and table_name='@{table_name}';
              ")
  result <- dbGetQuery(connection_name, query)
  return(result)
}

address_cols <- db_list_columns(connect, 'address')
bnf_cols <- db_list_columns(connect, 'bnf')
chemsubstance_cols <- db_list_columns(connect, 'chemsubstance')
gp_data_cols <- db_list_columns(connect, 'gp_data_up_to_2015')
qof_achievement_cols <- db_list_columns(connect, 'qof_achievement')
qof_indicator_cols <- db_list_columns(connect, 'qof_indicator')

address_cols
bnf_cols
chemsubstance_cols
gp_data_cols
qof_achievement_cols
qof_indicator_cols

# dbGetQuery(connect, "
#             SELECT min(practiceid), max(practiceid) from gp_data_up_to_2015
#             limit 50;
#            ")

search_df <- function(con, df_name, input) {
  print(input)
  query <- qq("
                SELECT * from @{df_name}
                WHERE lower(practiceid) like '@{input}' 
              ")
  result <- dbGetQuery(con, query)
  
  return(result)
  
}

guess_string <- readline(prompt="Enter a practiceid of your choice (q to quit):")
typeof(guess_string)
print(guess_string)
search_df(connect, 'gp_data_up_to_2015', guess_string)
# -----------------------------USER INPUT---------------------------------------

repeat{
  guess_string <- readline(prompt="Enter a practiceid of your choice (q to quit):")
  if (guess_string == "q"){
    break
  }
  
  if (is.na(guess)){
    cat("That guess (", guess_string, ") was not a number!\n")
    next
  }
  guesses <- c(guesses, guess)
  have_guessed <- guess == number
  attempts <- attempts + 1
  if (have_guessed == TRUE){
    cat("You guessed correctly, it was", number, "!\n")
    cat("You took", attempts, "goes to guess.\n")
    break
  } else {
    if (guess > number) {
      cat("You guessed too high, it wasn't", guess, "!\n")
    } else {
      cat("You guessed too low, it wasn't", guess, "!\n")
    }
    number <- number + round(runif(1, -change, change), 0)
    numbers <- c(numbers, number)
  } 
}

# -----------------------------DATA WRANGLE-------------------------------------

# -----------------------------VISUALIZE----------------------------------------
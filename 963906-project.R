# -----------------------------------------------------------
# 963906-project.R
# Assignment_Wales_Data.Rproj
# Version 20 - 20/03/2022
# Alex Jones
## This file is for the PMIM102J assignment for Scientific 
## Computing In Healthcare, it will make use of R and SQL
## to understand large datasets regarding health data in Wales
## and gain various insights on this data based on user inputs
## It follows the styleguide.txt
#### variables are lowerCamelCase
#### functions are under_scored_case
#### constants are UPPER_UNDER_SCORE_CASE
## All functions have been attempted to be named in a way that means minimal
## comments are needed however please refer to ReadMe.md for help
# -----------------------------------------------------------

# -----------------------------IMPORTS------------------------------------------
library(tidyverse) # for tidying up the datasets
library(crayon) # to change colours in the terminal for readability
library(GetoptLong);
require("RPostgreSQL") # require is the same as library but only throws a warning, not an error
#library(rlist) # for list searching capabilities


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

db_list_columns <- function(connectionName, tableName) {
  query <- qq("
              select
                column_name,
                ordinal_position,
                data_type,
                character_maximum_length,
                numeric_precision
              from INFORMATION_SCHEMA.COLUMNS
                where table_schema = 'public'
                and tableName='@{tableName}';
              ")
  result <- dbGetQuery(connectionName, query)
  return(result)
}

##########################################################
##########################################################
################ FUNCTIONS ###############################
##########################################################
##########################################################
user_input_practice <- function() {
  userInput <- readline(prompt="Enter a practiceid of your choice, there are 619, print-all (p), quit(q):")
  userInput <- trimws(toupper(userInput))
  if (userInput == "P") {
    print(LIST_PRACTICES_GP)
  }
  if (userInput == "Q") {
    cat("Quitting...")
  }
  
  return(userInput)
}

get_practices <- function(con, column, table) {
  query <- qq("
              SELECT DISTINCT @{column} from @{table}
              ")
  result <- dbGetQuery(con, query)
  return(result)
}


search_df_practice <- function(con, df_name, input) {
  # print(input)
  query <- qq("
                SELECT * from @{df_name}
                WHERE upper(practiceid) like '%@{input}%' 
              ")
  result <- dbGetQuery(con, query)
  
  return(result)
  
}

search_df_qof_org <- function(con, df_name, input) {
  # print(input)
  query <- qq("
                SELECT * from @{df_name}
                WHERE upper(orgcode) like '%@{input}%' 
              ")
  result <- dbGetQuery(con, query)
  
  return(result)
  
}

## outwardCode is the first part of a UK postcode
get_outcode <- function(con, practiceid) {
  query <- qq("
              SELECT LEFT(postcode, strpos(postcode, ' ') - 1) as outwardCode
              FROM address
              WHERE UPPER(address.practiceid) like '@{practiceid}%'
              ")
  result <- dbGetQuery(con,query)
  return(result)
  
}

select_practices_from_outcode <- function(con, outcode) {
  query <- qq("
              SELECT gp_data_up_to_2015.*, LEFT(postcode, strpos(postcode, ' ') - 1 ) as outwardCode
              FROM address
              INNER JOIN gp_data_up_to_2015
              ON address.practiceid = gp_data_up_to_2015.practiceid
              WHERE upper(address.postcode) like '@{outcode}%' 
              ")
  
  result <- dbGetQuery(con, query)
  return(result)
}

num_of_patients_sum_gp <- function(con, input) {
  # print(input)
  query <- qq("
                SELECT SUM(g.items) from gp_data_up_to_2015 as g
                WHERE upper(g.practiceid) like '%@{input}%' 
              ")
  result <- dbGetQuery(con, query)
  
  return(result)
  
}
num_of_patients_sum_qof <- function(con, input) {
  # print(input)
  query <- qq("
                SELECT MAX(q.field4) from qof_achievement as q
                WHERE upper(q.orgcode) like  '%@{input}'
              ")
  result <- dbGetQuery(con, query)
  
  return(result)
}

get_diabetes <- function(con, practiceid) {
  query <- qq("
              SELECT id,
                    year,
                    numerator,
                    field4,
                    ratio,
                    centile,
                    indicator,
                    active
                FROM qof_achievement
                WHERE UPPER(orgcode) like '@{practiceid}'
                AND UPPER(indicator) like 'DM001'
              ")
  result <- dbGetQuery(con, query)
  return(result)
}

get_wales_diabetes <- function(con) {
  # AND UPPER(q.orgcode) not like 'WAL'
  # ended on this line before but realised 1 extra row doesn't save much time
  # this could also be useful later
  query <- qq("
              SELECT q.numerator, q.field4, q.ratio, q.centile, q.orgcode
              FROM qof_achievement as q
              WHERE UPPER(q.indicator) like 'DM001'
              ")
  result <- dbGetQuery(con, query)
  return(result)
}

get_mental_health <- function(con, practiceid) {
  query <- qq("
              SELECT id,
                    year,
                    numerator,
                    field4,
                    ratio,
                    centile,
                    indicator,
                    active
                FROM qof_achievement
                WHERE UPPER(orgcode) like '@{practiceid}'
                AND UPPER(indicator) like '%MH 1%'
                OR UPPER(indicator) like '%DEP PREV 2%'
                OR UPPER(indicator) like '%DEP INCIDENCE%'
              ")
  result <- dbGetQuery(con, query)
  return(result)
}
## Function to return 2 queries, where we have total medicine not with that chem code prescribed
## and the total medicine with that chem code prescribed
get_medicine_prescribed <- function(con, chemCode) {
  chemCode <- toupper(chemCode)
  query <- qq("
                SELECT SUM(items) as medPrescribed, practiceid
                FROM gp_data_up_to_2015
                WHERE UPPER(bnfcode) like '%@{chemCode}%'
                GROUP BY practiceid
               ")
  
  result <- dbGetQuery(con, query)
  
  return(result)
}

get_prescribed_without_medicine <- function(con, chemCode) {
  chemCode <- toupper(chemCode)
  query <- qq("
                SELECT SUM(items) as nonMed, practiceid
                FROM gp_data_up_to_2015
                WHERE UPPER(bnfcode) not like '%@{chemCode}%'
                GROUP BY practiceid
               ")
  result <- dbGetQuery(con, query)
  return(result)
}

get_medicine <- function(con, chemCode) {
  chemCode <- toupper(chemCode)
  query <- qq("SELECT t1.practiceid, t1.medPrescribed, t2.nonmed, ROUND((CAST(t1.medPrescribed AS DECIMAL) /t2.nonMed)*100, 2) as medPercentage
                FROM
                (SELECT SUM(items) as medPrescribed, practiceid
                                FROM gp_data_up_to_2015
                                WHERE UPPER(bnfcode) like '%@{chemCode}%' 
                                GROUP BY practiceid) as t1
                				INNER JOIN
                (SELECT SUM(items) as nonmed, practiceid
                                FROM gp_data_up_to_2015
                                WHERE UPPER(bnfcode) not like '%@{chemCode}%'
                                GROUP BY practiceid) as t2
                				ON t1.practiceid = t2.practiceid;
              ")
  result <- dbGetQuery(con, query)
  return(result)
}

loop_input <- function(userInput) {
  inputResult <- match(userInput, unlist(LIST_PRACTICES_GP))
  while(nchar(userInput) != 6 | substr(userInput,1,1) != 'W' | is.na(inputResult)){
    userInput <- user_input_practice()
    if(userInput == "Q") {
      break
    }
    inputResult <- match(userInput, unlist(LIST_PRACTICES_GP))
  }
  return(userInput)
}

check_qof <- function(userInput, inputResultGP, inputResultQOF) {
  practiceSelected <- search_df_practice(connect, 'gp_data_up_to_2015', userInput)
  qofResult <- search_df_qof_org(connect, 'qof_achievement', userInput)
  if (!is.na(inputResultGP)){
    cat("Your input is legal and at index: ", inputResultGP, " here's a sample of the data.\n")
    print(head(practiceSelected))
    ### Check the practice has medication available - basically this should return some rows from GP_DATA if null then no info available
    ### Report if qof data is available, in this table orgcode is practiceid
    
  }
  if (!is.na(inputResultQOF)){
    if (nrow(practiceSelected) > 1 && nrow(qofResult) > 1) {
      cat('\n\t------Both the gp_data and qof tables contain data for the practice declared-------\n')
      cat('\t\tRows in the gp_data_2015 table are: ', nrow(practiceSelected), '\n')
      cat('\t\tRows in the qof_achievement table are: ', nrow(qofResult), '\n')
      cat('\t\tPractice |', userInput, '| is valid, continuing.\n')
      cat('\t-----------------------------------------------------------------------------------\n')
    }
  } else {
      cat(red('------One or both the gp_data and qof tables contain no data for the practice-------\n'))
      cat(red('\tRows in the gp_data_2015 table are: ', nrow(practiceSelected), '\n'))
      cat(red('\tRows in the qof_achievement table are: ', nrow(qofResult), '\n'))
      cat(red('\tPractice |', userInput, '| is not valid, please return to enter a correct val\n'))
      cat(red('-----------------------------------------------------------------------------------'))
      cat(red('\nPlease re-run the home() function\n'))
  }
  return(practiceSelected)
}

get_avg_spend <- function(userInput) {
  #### The average spend per month on medication
  avgquery_allWales <- qq("
                SELECT RIGHT(CAST(gp.period as TEXT), 2) as perMonth, ROUND(avg(nic)::numeric,2) as avgCost 
                FROM gp_data_up_to_2015 as gp
                GROUP BY RIGHT(CAST(gp.period as TEXT),2)
               ")
  avgquery_thisPractice <- qq("
                SELECT RIGHT(CAST(gp.period as TEXT), 2) as perMonth, ROUND(avg(nic)::numeric,2) as avgCost 
                FROM gp_data_up_to_2015 as gp
                WHERE UPPER(gp.practiceid) like '@{userInput}'
                GROUP BY RIGHT(CAST(gp.period as TEXT),2)
               ")
  avgPerMonth <- dbGetQuery(connect, avgquery_allWales)
  avgPerMonthCurrent <- dbGetQuery(connect, avgquery_thisPractice)
  typeof(avgPerMonth)
  totalAvg <- merge(avgPerMonth, avgPerMonthCurrent, by="permonth")
  totalAvg <- totalAvg %>%
    rename(
      "Month" = permonth,
      "£ Avg across Wales" = avgcost.x,
      "£ Avg at chosen practice" = avgcost.y
    )
  cat("\n") 
  print(totalAvg)
}


############################################################
##################    GRAPHS      ##########################
############################################################
visualise_spend <- function(userInput, numPatients) {
  #### Visualisation showing spend on medication per patient, compared to other practices (first part of postcode)
  #### per patient is using field 4
  #### postcode grouping is joining with address table
  #### group by LEFT function separated around " " operator
  
  outcode <- get_outcode(connect, userInput)$outwardcode
  practices <- select_practices_from_outcode(connect,outcode)
  
  cat("\nFirst part of postcode: ", outcode)
  # avg spend per patient for current practice
  # print(round((sum(avgPerMonth$avgcost)/numPatients),2))
  
  practices_key_data <- practices %>% select(-locality, -bnfcode, -quantity, -hb, -bnfname, -outwardcode, -period) 
  practices_key_data <- practices_key_data %>% mutate(avgPerItem = as.numeric(practices_key_data$nic/practices_key_data$items))
  # print(practices_key_data)
  
  practices_sum <- aggregate(x = practices_key_data[, colnames(practices_key_data) != "practiceid"],
                             by = list(practices_key_data$practiceid),
                             FUN = sum)
  
  practices_sum <- practices_sum %>% mutate(avgCost = as.numeric(nic/items))
  practices_sum <- practices_sum %>% mutate(perPatient = as.numeric(avgPerItem/numPatients))
  # print(practices_sum)
  
  ## Returns a df of 2 columns, the practiceid and the average spend per patient, now visualize
  practices_sum <- practices_sum %>% select(-nic,-items,-actcost,-avgPerItem,-avgCost)
  
  # visualize
  ##barplot(height=practices_sum$perPatient, practices_sum$perPatient, names=practices_sum$Group.1, xlab="Practice ID")
  xaxis <- paste("Practice ID for postcode: ",outcode)
  yaxis <- "Average spend per patient over 1 year"
  ggp_bars <- ggplot(practices_sum, aes(Group.1, perPatient)) +
    geom_bar(stat = "identity") +
    labs(y=yaxis, x=xaxis) + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))
  
  print(ggp_bars)
}

visualise_diab_box <- function(userInput) {
  ## Report the rate of diabetes at the practice, and visualize how this compares to 
  ## other practices in Wales. 
  
  # DM 1 is the indicator for patients on diabetic register
  # rate of diabetes = dm 1 / total patients
  # dm001 seems the most viable option, all patients over 17 with diabetes, even contains total patients and the percentage
  
  patients_diabetes <- get_diabetes(connect, userInput)
  cat("At the practice ", userInput," ", as.numeric(round(patients_diabetes$ratio*100,2)), "% of patients have diabetes.\n")
  cat("Or ", as.numeric(patients_diabetes$numerator), " of ", as.numeric(patients_diabetes$field4), " patients.\n")
  
  ## All wales list
  allDiabetes <- get_wales_diabetes(connect)
  allDiabetes <- allDiabetes[!allDiabetes$orgcode == "WAL",]
  print(summary(allDiabetes))
  
  
  ggp_box_diab <- ggplot() +
    geom_boxplot(data=allDiabetes, aes(y=ratio*100, x=field4)) +
    geom_hline(yintercept=allDiabetes[allDiabetes$orgcode == userInput,]$ratio*100, colour="red") +
    coord_flip() +
    labs(y="Rate of people with diabetes %", x="Number of patients")
  # 
  # ggp_box_depression <- ggplot() +
  #   geom_bar(data=merged, aes(y=dep_percentage, x=practiceid), colour="black", stat='identity') +
  #   geom_bar(data=merged, aes(y=medpercentage, x=practiceid), colour="grey", fill="red", stat='identity') +
  #   labs(y=percentageDepression, x=depressionPractices) +
  #   scale_x_discrete(labels = abbreviate) +
  #   theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size=6))
  
  print(ggp_box_diab)
}

visualise_dot_plot <- function(userInput) {
  
  ## All wales list
  allDiabetes <- get_wales_diabetes(connect)
  allDiabetes <- allDiabetes[!allDiabetes$orgcode == "WAL",]
  patients_diabetes <- get_diabetes(connect, userInput)
  ## organising into rest of wales and current practice
  diab_wales_plot <- allDiabetes[!allDiabetes$orgcode == userInput,]
  diab_practice_plot <- patients_diabetes
  
  diab_plot <- ggplot()  +
    # rest of wales
    geom_point(data=diab_wales_plot, aes(x=ratio*100, y=field4), colour="black") +
    # this practice
    geom_point(data=diab_practice_plot, aes(x=ratio*100, y=field4), colour="red", size=5)
  
  
  diab_plot + ggtitle("Plot displaying all diabetes across Welsh Practices") +
    xlab("Percentage of people with diabetes") +
    ylab("Total patients at the practice")
  
  print(diab_plot)
}

####################################
#################### MENU FOR GRAPH
####################################
####################################

graph_menu <- function(userInput, numPatients) {
  ## \014 clears the console
  ## \012 is a newline
  cat(green("Enter 1 for spend visualisation\n"))
  cat(green("Enter 2 for dot-plot visualisation (rate of diabetes vs other practices)\n"))
  cat(green("Enter 3 for box-whisker visualisation (rate of diabetes vs insulin vs metformin)\n"))
  cat(green("Enter c to continue"))
  graphInput <- readline("Choose one of the above options:")
  while(nchar(graphInput) != 1 | tolower(graphInput) != "c"){
    if (graphInput == "1"){
        visualise_spend(userInput, numPatients)
    } else if(graphInput == "2") {
       visualise_diab_box(userInput)   
    } else if(graphInput=="3"){
      visualise_dot_plot(userInput)
    } else {
      cat("Try again, as above...")
    }
    graphInput <- ""
    graphInput <- readline("Choose one of the above options:")
  }
}

insulin_ttest <- function(userInput) {
  
  ## All wales list
  allDiabetes <- get_wales_diabetes(connect)
  allDiabetes <- allDiabetes[!allDiabetes$orgcode == "WAL",]
  ### Finally, perform an all-Wales analysis comparing the rate of diabetes and the rate of insulin 
  ### prescribing at a practice level. Is there a statistically significant relationship between the two? 
  diab_wales <- allDiabetes[!allDiabetes$orgcode == "WAL",]
  
  ## get the mean of people with diabetes
  diab_sum <- summary(allDiabetes[!allDiabetes$orgcode == "WAL",])
  
  #as.numeric(sub('.*:', '', diab_sum[4,3]))
  diabetes_ratio <- mean(allDiabetes[!allDiabetes$orgcode == "WAL",]$ratio)
  ## get the mean of insulin prescribed per practice
  insulin_prescribed <- get_medicine_prescribed(connect, INSULIN_CODE)
  insulin_not_prescribed <- get_prescribed_without_medicine(connect, INSULIN_CODE)
  
  joined_ins <- merge(insulin_prescribed, insulin_not_prescribed, by = "practiceid", all.x = TRUE, all.y = FALSE)
  joined_ins <- joined_ins %>% mutate(presRatio = as.numeric(medprescribed/nonmed))
  head(joined_ins)
  prescribedRation <- mean(joined_ins$presRatio)
  
  ## compare with t-test
  cat("---------INSULIN V DIABETES T TEST ----------------")
  print(t.test(x=diab_wales$ratio, y=joined_ins$presRatio))
  wilcox.test(x=diab_wales$ratio, y=joined_ins$presRatio)
  
  ######### Both less than 0.05 being 2.2e-16 so is statistically significant
  
  ###Repeat using metformin instead of insulin. If you find statistically significant relationships, which 
  ### is stronger? 
  metformin_prescribed <- get_medicine_prescribed(connect, METFORMIN_CODE)
  metformin_not_prescribed <- get_prescribed_without_medicine(connect, METFORMIN_CODE)
  
  joined_met <- merge(metformin_prescribed, metformin_not_prescribed, by = "practiceid", all.x = TRUE, all.y = FALSE)
  joined_met <- joined_met %>% mutate(presRatio = as.numeric(medprescribed/nonmed))
  head(joined_met)
  prescribedRation <- mean(joined_met$presRatio)
  ## compare with t-test
  #shapiro.test(diab_wales$ratio)
  cat("---------METFORMIN V DIABETES T TEST ----------------")
  print(t.test(x=diab_wales$ratio, y=joined_met$presRatio, alternative = c("two.sided", "less", "greater")))
  boxplot(diab_wales$ratio*100, joined_ins$presRatio*100, joined_met$presRatio*100, names=c('Diabetes rate', 'Insulin prescription rate', 'Metformin prescription rate'), outline=FALSE)
  wilcox.test(x=diab_wales$ratio, y=joined_met$presRatio)
}


# -----------------------------PART II-------------------------------------
# Trying to find a link between mental health and depression and medication prescribed
# MH 1 is mental health
# Dep Incidence = The number of new diagnoses of depression in the practice during this QOF year.
# Dep 1 = last 15 months depression
# Dep Prev 3 = depression history since april 2006

## statistical significance between depression rates at chosen practice and rate of contraception prescription
#  like '%microgynon%' or lower(bnfname) like '%rigevidon%' or lower(bnfname) like '%ovranette%'
open_analysis_part_2 <- function(userInput) {
  queryDepression <- qq("
              SELECT id,
                    year,
                    numerator,
                    field4,
                    ratio,
                    centile,
                    indicator,
                    active,
                    orgcode
                FROM qof_achievement
                WHERE UPPER(orgcode) like '@{userInput}'
                AND UPPER(indicator) like '%@{DEP_CODE}%'
              ")
  patientsDepression <- dbGetQuery(connect, queryDepression)
  
  walesDepQuery <- qq("
              SELECT numerator,
                    field4,
                    ratio,
                    centile,
                    orgcode as practiceid
                FROM qof_achievement
                WHERE UPPER(indicator) like 'DEP PREV 3%'
              ")
  
  walesDepression <- dbGetQuery(connect, walesDepQuery)
  
  
  cat("At the practice ", userInput," ", as.numeric(round(patientsDepression$ratio*100,2)), "% of patients have depression (", as.numeric(patientsDepression$numerator), "/", as.numeric(patientsDepression$field4), ")")
  query_mh <- qq("
              SELECT id,
                    year,
                    numerator,
                    field4,
                    ratio,
                    centile,
                    indicator,
                    active
                FROM qof_achievement
                WHERE UPPER(orgcode) like '@{userInput}'
                AND UPPER(indicator) like '%@{MH_CODE}%'
              ")
  patientsMentalHealth <- dbGetQuery(connect, query_mh)
  
  
  cat("\nAt the practice ", userInput," ", as.numeric(round(patientsMentalHealth$ratio*100,2)), "% of patients are on the mental health register (", as.numeric(patientsMentalHealth$numerator), "/", as.numeric(patientsMentalHealth$field4), ")")
  
  return(walesDepression)
}

contraceptives_wales <- function(walesDepression,userInput) {
  query_contraceptives <- qq("
                SELECT bnfname, practiceid, SUM(items) as medPrescribed, SUBSTRING(bnfname, 0, STRPOS(bnfname, '_')) AS string
                FROM gp_data_up_to_2015
                WHERE UPPER(bnfcode) like '%@{CONTRACEPTIVES}%'
                AND UPPER(practiceid) like '@{userInput}'
                GROUP BY bnfname, practiceid
               ")
  
  get_contraceptives_wales <- get_medicine(connect, CONTRACEPTIVES)
  get_prescribed_at_practice <- get_contraceptives_wales %>% filter(practiceid == userInput)
  patients_contraceptives <- dbGetQuery(connect, query_contraceptives)
  
  prescription_fraction <- as.numeric(get_prescribed_at_practice$medprescribed)/as.numeric(get_prescribed_at_practice$nonmed)
  
  cat(as.numeric(sum(patients_contraceptives$medprescribed)), " contraceptives were prescribed out of ", get_prescribed_at_practice$nonmed, " which is ", round(prescription_fraction*100,2), "%")
  
  merged <- merge(walesDepression, get_contraceptives_wales, by="practiceid")
  merged$ratio <- round((as.numeric(merged$ratio)*100),2)
  merged <- rename(merged, dep_percentage=ratio)
  cat("---------DEPRESSION V PRESCRIBED CONTRACEPTIVES T TEST ----------------")
  print(t.test(as.numeric(merged$dep_percentage), merged$medpercentage))
  return(merged)
}

####################################
################ MENU FOR DEPRESSION
####################################
####################################

graph_menu_depression <- function(userInput, merged) {
  ## \014 clears the console
  ## \012 is a newline
  cat(green("Enter 1 for depression histogram\n"))
  cat(green("Enter 2 for dot-plot visualisation\n"))
  cat(green("Enter c to continue"))
  graph_input <- readline("Choose one of the above options:")
  while(nchar(graph_input) != 1 | tolower(graph_input) != "c"){
    if (graph_input == "1"){
      dep_histo_plot(merged)
    } else if(graph_input == "2") {
      dep_dot_plot(merged, userInput)  
    } else {
      cat("Try again, as above...")
    }
    graph_input <- ""
    graph_input <- readline("Choose one of the above options:")
  }
}
dep_histo_plot <- function(merged) {
  
  depressionPractices <- "Graph displaying depression percentages across practices"
  percentageDepression <- "Percentage of depression (black) and contraceptive prescription (red)"
  merged <- merged %>% filter (dep_percentage < 5.0)
  ggp_box_depression <- ggplot() +
    geom_bar(data=merged, aes(y=dep_percentage, x=practiceid), colour="black", stat='identity') +
    geom_bar(data=merged, aes(y=medpercentage, x=practiceid), colour="grey", fill="red", stat='identity') +
    labs(y=percentageDepression, x=depressionPractices) +
    scale_x_discrete(labels = abbreviate) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size=6))
  
  print(ggp_box_depression)
}

dep_dot_plot <- function(merged, userInput) {
  dep_dot <- ggplot()  +
    # rest of wales
    geom_point(data=merged[!merged$practiceid == userInput,], aes(x=medpercentage, y=dep_percentage), colour="black") +
    # this practice
    geom_point(data=merged[merged$practiceid == userInput,], aes(x=medpercentage, y=dep_percentage), colour="red", size=5) +
    labs(y="Rate of depression %", x="Contraceptive prescription rate %")
  
  print(dep_dot)
}

## Home function

home <- function() {
  ## \014 clears the console
  ## \012 is a newline
  cat(bgGreen("\014\nPMIM102J Assignment - 963906\n")
      %+% green("---------------------------------------------------------------\n"))
  userInput <- loop_input("")
  inputIsValidGP <- match(userInput, unlist(LIST_PRACTICES_GP))
  inputIsValidQOF <- match(userInput, unlist(LIST_PRACTICES_QOF))
  
  practiceSelected <- check_qof(userInput, inputIsValidGP, inputIsValidQOF)
  
    
  #### Number of patients at practice
  ###### This is a weird one because each item in gp_data_practices_2015 is linked to a single prescription form, however this doesn't 
  ###### necessarily mean that the individual prescriptions links to a unique person, and all prescriptions could technically be one patient
  
  practice_trimmed <- practiceSelected %>% select(-bnfname, -period) 
  numPatientsQOF <- num_of_patients_sum_qof(connect, userInput)
  numPatients <- as.numeric(unlist(numPatientsQOF))
  cat('QOF says (field4) that there are:', numPatients, ' patients.\n')
  
  get_avg_spend(userInput)
  
  tryCatch({graph_menu(userInput, numPatients)}, finally={cat("Graphs displayed, t-test now: \n")})
  insulin_ttest()
  
  cat(blue("INSULIN has a: \n"))
  cat(blue("\tt value | 82.25 \n"))
  cat(blue("\tdf value | 743.31\n"))
  cat(blue("\tp value of less than 2.2e-16\n"))
  cat(blue("---------------------------\n"))
  cat(blue("METFORMIN has a: \n"))
  cat(blue("\tt value | -36.77 \n"))
  cat(blue("\tdf value | 517.04\n"))
  cat(blue("\tp value of less than 2.2e-16\n"))
  cat(blue("They both have similar p-values and statistical significan, which makes sense as both medicines are for diabetes\n"))
  cat(blue("however insulin is more statistically significant as the t value is greater meaning a greater difference in groups compared\n"))
  cat(blue(" both are statistically significant as both p-values are approaching 0\n"))
  
  cat(green("PART II - A check on if contraceptive prescription has significance on depression rate at practice\n")
      %+% green("---------------------------------------------------------------\n"))
  change_practice <- readline("WOULD YOU LIKE TO CHANGE THE PRACTICE? (Y/N): ")
  
  if(toupper(change_practice) == "Y"){
    userInput <- loop_input("")
    inputIsValidGP <- match(userInput, unlist(LIST_PRACTICES_GP))
    inputIsValidQOF <- match(userInput, unlist(LIST_PRACTICES_QOF))
    
    practiceSelected <- check_qof(userInput, inputIsValidGP, inputIsValidQOF)
  }
  walesDepression <- open_analysis_part_2(userInput)
  merged <- contraceptives_wales(walesDepression, userInput)
  graph_menu_depression(userInput, merged)
}

################################################################################
# -----------------------------CONSTANTS---------------------------------------
################################################################################
INSULIN_CODE <- '060101' # can have values after
METFORMIN_CODE <- '060102' # as above
DEP_CODE <- 'DEP PREV 3' # on further review this should include everyone that has ever been diagnosed with depression in the practice
# below is all dep 3 depression codes
# DEP_CODE <- 'DEP%3'
MH_CODE <- 'MH001'
CONTRACEPTIVES <- '0703010F0B'

LIST_PRACTICES_GP <- get_practices(connect, 'practiceid', 'gp_data_up_to_2015')
LIST_PRACTICES_QOF <- get_practices(connect, 'orgcode', 'qof_achievement')

################################################################################
# -----------------------------MAIN FUNCTION------------------------------------
################################################################################
home()

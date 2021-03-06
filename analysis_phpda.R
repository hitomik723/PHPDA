###########################
# title: "analysis_phpda"
# author: "Hitomi Kariya"
# date: "9/5/2019"
# output: html_document
###########################

##### Prepare for the analysis #####
library(foreign)
library(data.table)
library(tidyverse)
library(survey)
library(multcomp)
#setwd("~/Documents/MPH/Practicum/PHPDA")
rm(list=ls())

##### Import df15_sub #####
#df15_sub = a subset of data filtered to the related variables in Wasington state
df15 <- read.csv("https://raw.githubusercontent.com/HitomiKariya/PHPDA/master/df15_sub.csv?token=ALVLXKGL25TJOKXT5AA7VHK5SK7N2")
#when not conneted to the internet
#df15 <- read.csv("df15_sub.csv")
colnames(df15)
head(df15)
df15$HPVADVC2 <- NULL #Delete since it has only NA

##### Check for missing #####
sapply(df15, function(x) sum(is.na(x)))

##### Recode variables #####

########## Race Asian as Reference
#Originally coded as...
#X_RACE: 1 = White, 2 = Black, 4 = Asian, 8 = Hispanic
#Now coding into...
#race: 0 = Asian, 1 = White, 2 = Black, 3 = Hispanic, 4 = Others
df15$race <- ifelse(df15$X_RACE == 1, 1, NA) #White = 1
df15$race <- ifelse(df15$X_RACE == 2, 2, df15$race) #Black = 2
df15$race <- ifelse(df15$X_RACE == 8, 3, df15$race) #Hispanic = 3
df15$race <- ifelse(df15$X_RACE == 4, 0, df15$race) #Asian = 0
df15$race <- ifelse(df15$X_RACE == 3 | df15$X_RACE == 5 | df15$X_RACE == 6 | df15$X_RACE == 7, 4, df15$race) #Others = 4
head(df15$race)
df15$race <- as.factor(df15$race)
table(df15$race)

########## Education
#Originally coded as a six-level category
#Now coding into...
#education: 0 = High school & less, 1 = college & more
df15$education <- ifelse(df15$EDUCA == c(1:4), 0, 1)
#High school & less = 0, college & more = 1
df15$education <- ifelse(df15$EDUCA == 9, NA, df15$education)
#Excluding the refused
table(df15$education)
sum(is.na(df15$education))
head(df15)

########## Age
#Originally coded as a fourteen-level category
#coding into 5 categories
df15$age <- ifelse(df15$X_AGEG5YR == 1 | df15$X_AGEG5YR == 2, 0, NA) #18-29 = 0
df15$age <- ifelse(df15$X_AGEG5YR == 3 | df15$X_AGEG5YR == 4, 1, df15$age) #30-39 = 1
df15$age <- ifelse(df15$X_AGEG5YR == 5 | df15$X_AGEG5YR == 6, 2, df15$age) #40-49 = 2
df15$age <- ifelse(df15$X_AGEG5YR == 7 | df15$X_AGEG5YR == 8, 3, df15$age) #50-59 = 3
df15$age <- ifelse(df15$X_AGEG5YR == 9, 4, df15$age) #60-64 = 4
df15$age <- ifelse(df15$X_AGEG5YR >= 10, 5, df15$age) #65- = 5
table(df15$age)
#coding into 2 categories
df15$age <- ifelse(df15$age == 0, 0, ifelse(df15$age >= 1 & df15$age <= 4, 1, ifelse(df15$age == 5, NA, NA)))
table(df15$age)
#18 - 29 = 0, 30 - 64 = 1, 65+ = NA

########## Outcome (Cervical Screening)
#Originally coded as...
#HADPAP2 == 2 = No (Haven't ever had a Pap test)
#HADPAP2 == 1 = Yes (Have ever had a Pap test)
#HADPAP2 == 7 = Don't know/Not sure ---> #Included Don't know as No (0)
#HADPAP2 == 9 = Refused
#LASTPAP2 == 4 = Had a Pap test within the past 5 years
#LASTPAP == 5 = Had a Pap test 5 or more years ago 
#LASTPAP == 7 = Don't know/not sure 
#Now coding into...
#Not recieving a screening within 3 years = 0
#Have received a screening withing 3 years = 1
df15$cervical_sc <- ifelse(df15$HADPAP2 == 2 | (df15$HADPAP2 == 1 & (df15$LASTPAP2 == 4 | df15$LASTPAP2 == 5 | df15$LASTPAP2 == 7)) | df15$HADPAP2 == 7, 0, NA)
df15$cervical_sc <- ifelse(df15$HADPAP2 == 1 & (df15$LASTPAP2 == 1 | df15$LASTPAP2 == 2 | df15$LASTPAP2 == 3), 1, df15$cervical_sc)
table(df15$cervical_sc)
sum(is.na(df15$cervical_sc))

########## Exposure (Marriage status)
#Originally coded as...
#MARITAL == 1 = Married
#MARITAL == 2 = Divorced
#MARITAL == 3 = Widowed
#MARITAL == 4 = Separated
#MARITAL == 5 = Never Married
#MARITAL == 6 = Unmarried couple
#MARITAL == 9 = Refused
#Now coding into...
#Never married = 0
#Married & Marriage experience & Unmarried couple = 1
#Refused will be NA
df15$marriage <- ifelse(df15$MARITAL == 5, 0, NA)
df15$marriage <- ifelse(df15$MARITAL == 1 | df15$MARITAL == 2 | df15$MARITAL == 3 | df15$MARITAL == 4 | df15$MARITAL == 6, 1, df15$marriage)
table(df15$marriage)
sum(is.na(df15$marriage))

########## Exposure (Mammogram experience)
#Originally coded as...
#HADMAM == 2 = No (Haven't ever had a HADMAM test)
#HADMAM == 1 = Yes (Have ever had a HADMAM test)
#HADMAM == 7 = Don't know/Not sure
#HADMAM == 9 = Refused
#Now conding into...
#Not recieving a mammogram within 3 years = 0
#Have received a mammogram withing 3 years = 1
df15$mammogram <- ifelse(df15$HADMAM == 2 | (df15$HADMAM == 1 & (df15$HOWLONG == 4 | df15$HOWLONG == 5 | df15$HOWLONG == 7)) | df15$HADMAM == 7, 0, NA)
df15$mammogram <- ifelse(df15$HADMAM == 1 & (df15$HOWLONG == 1 | df15$HOWLONG == 2 | df15$HOWLONG == 3), 1, df15$mammogram)
table(df15$mammogram)
sum(is.na(df15$mammogram))

########## Exposure (Employment)
#Originally coded as...
#EMPLOY1 == 1 = Employed for wages
#EMPLOY1 == 2 = Self-employed
#EMPLOY1 == 3 = Out of work for 1 year or more
#EMPLOY1 == 4 = Out of work for less than 1 year
#EMPLOY1 == 5 = A homemaker
#EMPLOY1 == 6 = A student
#EMPLOY1 == 7 = Retired
#EMPLOY1 == 8 = Unable to work
#EMPLOY1 == 9 = Refused
#Now coding into...
#Employed = 1 (1, 2, 5, 6)
#Unemployed = 0 (3, 4, 8)
#Retired, Unable to work & Refused will be NA
###? Retired can be excluded? CHECK literature
df15$employment <- ifelse(df15$EMPLOY1 == 1 | df15$EMPLOY1 == 2 | df15$EMPLOY1 == 5 | df15$EMPLOY1 == 6, 1, NA)
df15$employment <- ifelse(df15$EMPLOY1 == 3 | df15$EMPLOY1 == 4 | df15$EMPLOY1 == 8, 0, df15$employment)
table(df15$employment)
sum(is.na(df15$employment))

########## Exposure (Healthcare)
#Originally coded as...
#HLTHPLN1 == 1 = Yes (Have healthcare coverage)
#HLTHPLN1 == 2 = No (Don't have healthcare coverage)
#HLTHPLN1 == 7 = Don't know/Not sure
#HLTHPLN1 == 9 = Refused
#Now coding into...
#Have healthcare = 1
#Don't have healthcare = 0
#Don't know/Not sure & Refused will be NA
df15$healthcare <- ifelse(df15$HLTHPLN1 == 1, 1, NA)
df15$healthcare <- ifelse(df15$HLTHPLN1 == 2, 0, df15$healthcare)
table(df15$healthcare)
sum(is.na(df15$healthcare))

##### Table 1.Population characteristics (Weighted)
### Create survey design

###narrowing down to only those who are under 65
df15 <- df15 %>% filter (age == 0 | age == 1)
options(survey.lonely.psu = "adjust")
design <- svydesign(data = df15, id=~X_PSU, strata = ~strata, weight = ~weight, nest = TRUE)
########## Sample size
table(df15$race) #Sample size (unweighted)
#race: White = 1, Black = 2, Hispanic = 3, Asian = 0, #Others = 4

prop.table(svytable(~race, design = design)) #Weighted proportion
########## Population characteristics
##age: 0 = 18 -29 years old 1 = 30 - 64 years old
prop.table(svytable(~age, subset(design, race == 0))) #Asian
prop.table(svytable(~age, subset(design, race == 1))) #White
prop.table(svytable(~age, subset(design, race == 2))) #Black
prop.table(svytable(~age, subset(design, race == 3))) #Hispanic
prop.table(svytable(~age, subset(design, race == 4))) #Other
##education: High school & less = 0, college & more = 1
prop.table(svytable(~education, subset(design, race == 0))) #Asian
prop.table(svytable(~education, subset(design, race == 1))) #White
prop.table(svytable(~education, subset(design, race == 2))) #Black
prop.table(svytable(~education, subset(design, race == 3))) #Hispanic
prop.table(svytable(~education, subset(design, race == 4))) #Other
##marriage: Never married = 0, Married & Marriage experience & Unmarried couple = 1
prop.table(svytable(~marriage, subset(design, race == 0))) #Asian
prop.table(svytable(~marriage, subset(design, race == 1))) #White
prop.table(svytable(~marriage, subset(design, race == 2))) #Black
prop.table(svytable(~marriage, subset(design, race == 3))) #Hispanic
prop.table(svytable(~marriage, subset(design, race == 4))) #Other
##employment: Employed = 1, Unemployed = 0
prop.table(svytable(~employment, subset(design, race == 0))) #Asian
prop.table(svytable(~employment, subset(design, race == 1))) #White
prop.table(svytable(~employment, subset(design, race == 2))) #Black
prop.table(svytable(~employment, subset(design, race == 3))) #Hispanic
prop.table(svytable(~employment, subset(design, race == 4))) #Other
##healthcare: Have healthcare = 1, Don't have health care = 0
prop.table(svytable(~healthcare, subset(design, race == 0))) #Asian
prop.table(svytable(~healthcare, subset(design, race == 1))) #White
prop.table(svytable(~healthcare, subset(design, race == 2))) #Black
prop.table(svytable(~healthcare, subset(design, race == 3))) #Hispanic
prop.table(svytable(~healthcare, subset(design, race == 4))) #Other

##### Table 2. #####
########## Weighted Prevalence of receiving a screening within three years
prop.table(svytable(~cervical_sc, subset(design, race == 0))) #Asian
prop.table(svytable(~cervical_sc, subset(design, race == 1))) #White
prop.table(svytable(~cervical_sc, subset(design, race == 2))) #Black
prop.table(svytable(~cervical_sc, subset(design, race == 3))) #Hispanic
prop.table(svytable(~cervical_sc, subset(design, race == 4))) #Other

##### Table 3. #####
########## Weighted Prevalence of receiving a screening within three years by marriage status
prop.table(svytable(~cervical_sc, subset(design, race == 0 & marriage == 0))) #Asian unmarried
prop.table(svytable(~cervical_sc, subset(design, race == 0 & marriage == 1))) #Asian Married
prop.table(svytable(~cervical_sc, subset(design, race == 1 & marriage == 0))) 
prop.table(svytable(~cervical_sc, subset(design, race == 1 & marriage == 1)))
prop.table(svytable(~cervical_sc, subset(design, race == 2 & marriage == 0))) 
prop.table(svytable(~cervical_sc, subset(design, race == 2 & marriage == 1)))
prop.table(svytable(~cervical_sc, subset(design, race == 3 & marriage == 0))) 
prop.table(svytable(~cervical_sc, subset(design, race == 3 & marriage == 1)))
prop.table(svytable(~cervical_sc, subset(design, race == 4 & marriage == 0))) #
prop.table(svytable(~cervical_sc, subset(design, race == 4 & marriage == 1)))

##### Logistic Regression #####
df15$marriage <- as.factor(df15$marriage)
df15$education <- as.factor(df15$education)
df15$age <- as.factor(df15$age)
df15$race <- as.factor(df15$race)
head(df15)
df15$employment <- as.factor(df15$employment)
head(df15)
df15$healthcare <- as.factor(df15$healthcare)
head(df15)

########## Aim1
options(survey.lonely.psu = "adjust")
design <- svydesign(data = df15, id=~X_PSU, strata = ~strata, weight = ~weight, nest = TRUE)
ratio <- svyglm(cervical_sc ~ as.factor(marriage) + as.factor(education) + as.factor(age) + as.factor(race) + as.factor(employment) + as.factor(healthcare), design = design, family = binomial)
summary(ratio)

###Get estimates
exp(coef(ratio))
#Each estimate of the each racial group corresponds to each of the as.factor(race)1~4
exp(confint(ratio))#When ref = white, OR of receving a screening within 3 years comparing Asian to Whites is 0.56,
#where Asians have 44% lower odds of receiving.
# Likelihood ratio test
#Look at Slides11_BIOST513_050619 @page 30
nested <- svyglm(cervical_sc ~ as.factor(marriage) + as.factor(education) + as.factor(age) + as.factor(employment) + as.factor(healthcare), design = design, family = binomial)
anova(nested, ratio, test = "Chisq", method = "LRT")
#Since the p-value is 2.4664e-08, there is an association between screening behaviro and race.

########## Aim2
#Interaction marriage*race?
#including employment and healthcare
ratio_interaction <- svyglm(cervical_sc ~ as.factor(marriage) + as.factor(education) + as.factor(age) + as.factor(race) + as.factor(employment) + as.factor(healthcare) + as.factor(marriage)*as.factor(race), design = design, family = binomial)
summary(ratio_interaction)
confint(ratio_interaction)
exp(coef(ratio_interaction))
exp(confint(ratio_interaction))
# Get estimate for Asian

###Get estimates of PR comparing the married to the unmarried among each racial/ethnic group
b0 <- -2.0096 #coef: intercept
b1 <- 1.5825 #coef: (marriage)1
b4_white <- 1.2742 #coef: (race)1
b7_white <- -1.1221 #coef: (marriage)1:(race)1
b4_black <- 2.7211 
b7_black <- -1.8711
b4_hispanic <- 1.2500
b7_hispanic <- -0.4987
b4_other <- 0.9962
b7_other <- -1.0221
#Asian
exp(b1) #Exp(coef: (marriage)1)
#White
exp(b1 + b7_white)
#Black
exp(b1 + b7_black)
#Hispanic
exp(b1 + b7_hispanic)
#Other
exp(b1 + b7_other)
# Likelihood ratio test
nested <- svyglm(cervical_sc ~ as.factor(marriage) + as.factor(education) + as.factor(age) + as.factor(race) + as.factor(employment) + as.factor(healthcare), design = design, family = binomial)
anova(nested, ratio_interaction, test = "Chisq", method = "LRT")
# Since the p-value is p= 0.055804, there is no statistical difference in the association of the screening behavior and marriage status by race.

### Get 95% CI
b1_low <- 0.59987949 #confint: (marriage)1 2.5%
b1_high <- 2.56506157 #confint: (marriage)1 97.5%
b7_white_low <- -2.11928411 #confint: (marriage)1:(race)1 2.5%
b7_white_high <- -0.12498297 #confint: (marriage)1:(race)1 97.5%
b7_black_low <- -3.82144443
b7_black_high <- 0.07928532
b7_hispanic_low <- -1.69282076
b7_hispanic_high <- 0.69546403
b7_other_low <- -2.27427109
b7_other_high <- 0.22999562
#Asian
exp(b1_low) #Exp(confint: (marriage)1 2.5%)
exp(b1_high) #Exp(confint: (marriage)1 97.5%)
#White
exp(b1_low + b7_white_low) #Exp(confint: (marriage)1 2.5% + confint: (marriage)1:(race)1 2.5%)
exp(b1_high + b7_white_high) #Exp(confint: (marriage)1 97.5% + confint: (marriage)1:(race)1 97.5%)
#Black
exp(b1_low + b7_black_low)
exp(b1_high + b7_black_high)
#Hispanic
exp(b1_low + b7_hispanic_low)
exp(b1_high + b7_hispanic_high)
#Other
exp(b1_low + b7_other_low)
exp(b1_high + b7_other_high)

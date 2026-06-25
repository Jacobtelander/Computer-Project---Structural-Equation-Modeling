library(readr)
library(tidyr)
library(corrplot)
library(tidyverse)
library(psych)
library(lavaan)
library(semPlot)
library(semTools)

####Clean data####--------------------------------------------------------------

#Data contains stats from all matches every player has played. To analyze overall ability,
#conversion to overall stars firstly has to be performed.
nba <- read_delim("NBA_data_CI-course.csv", 
                                 delim = ";", escape_double = FALSE, trim_ws = TRUE)
View(nba)

#Selecting variables for cfa
nba2 <- nba %>%
  select(Player, PTS, `FG%`, `3P%`, AST,
         ORB, FT, STL, BLK, DRB, TRB, TOV)

#Creating overall stats for players, rounded to 3 decimals
nba_player <- nba2 %>%
  group_by(Player) %>%
  summarise(
    PTS =  round(mean(PTS, na.rm = TRUE), 3),
    goal_procent = round(mean(`FG%`, na.rm = TRUE), 3),
    threeP_procent = round(mean(`3P%`, na.rm = TRUE), 3),
    AST = round(mean(AST, na.rm = TRUE), 3),
    ORB = round(mean(ORB, na.rm = TRUE), 3),
    FT = round(mean(FT, na.rm = TRUE), 3),
    STL = round(mean(STL, na.rm = TRUE), 3),
    BLK = round(mean(BLK, na.rm = TRUE), 3),
    DRB = round(mean(DRB, na.rm = TRUE), 3),
    TRB = round(mean(TRB, na.rm = TRUE), 3),
    TOV = round(mean(TOV, na.rm = TRUE), 3)
  )

View(nba_player)
colSums(is.na(nba_player))


####Descriptive statistics####--------------------------------------------------

#We select all except the player variable
describe(nba_player %>% select(-Player))


# Correlation matrix
cor_matrix <- cor(
  nba_player %>% select(-Player),
  use = "pairwise.complete.obs")

round(cor_matrix, 2)

corrplot(
  cor_matrix,
  method = "color",
  type = "upper",
  addCoef.col = "black",
  tl.col = "black",
  number.cex = 0.7)



nba_scaled <- nba_player %>%
  mutate(across(-Player, scale))




####First model####-------------------------------------------------------------

model1 <- '
Offense =~ PTS + AST + FT

Defense =~ STL + BLK + DRB + TRB

# correlated residuals
PTS ~~ FT'

#We use fiml as method to deal with missing values and MLR as robust estimator
fit1 <- cfa(
  model1,
  data = nba_player,
  estimator = "MLR",
  missing = "fiml"
)

summary(
  fit1,
  fit.measures = TRUE,
  standardized = TRUE
)

semPaths(
  fit1,
  what = "std",
  layout = "tree",
  residuals = FALSE,
  intercepts = FALSE,
  edge.label.cex = 1.1,
  sizeLat = 8,
  sizeMan = 7,
  nCharNodes = 0,
  curvePivot = TRUE,
  style = "lisrel",
  rotation = 1
)


####Revised model####-----------------------------------------------------------

model2 <- '

Off_inv =~ PTS + AST + FT + TOV

Interior =~ ORB + BLK + DRB

AST ~~ TOV
PTS ~~ FT
ORB ~~ BLK

Interior ~ Off_inv
'



#We use fiml as method to deal with missing values and MLR as robust estimator
fit2 <- cfa(
  model2,
  data = nba_scaled,
  estimator = "MLR",
  missing = "fiml"
)

summary(
  fit2,
  fit.measures = TRUE,
  standardized = TRUE
)

modindices(fit, sort = TRUE, minimum.value = 10)
reliability(fit)


semPaths(
  fit2,
  what = "std",
  layout = "tree",
  residuals = FALSE,
  intercepts = FALSE,
  edge.label.cex = 1.1,
  sizeLat = 8,
  sizeMan = 7,
  nCharNodes = 0,
  curvePivot = TRUE,
  style = "lisrel",
  rotation = 1
)




####Cornbach alpha####----------------------------------------------------------
alpha(nba_player[, c("PTS","AST","FT")])

alpha(nba_player[, c("STL","BLK","DRB","TRB")])

alpha(nba_player[, c("PTS","AST","FT","TOV")])

alpha(nba_player[, c("ORB","BLK","DRB")])




####unclear if we need#####-----------------------------------------------------------------
scores <- lavPredict(fit)

head(scores)

player_scores <- as.data.frame(scores) %>%
  mutate(Player = nba_player$Player) %>%
  select(Player, Off_inv, Interior)

colnames(player_scores) <- c("Player", "Off_inv", "Interior")

player_scores %>%
  arrange(desc(Off_inv))

player_scores %>%
  arrange(desc(Interior))




#### Rookies vs Veterans Analysis ####-----------------------------------------

# The original dataset does not contain a rookie/veteran variable.
# Therefore, we manually create a list of rookie players.

rookie_names <- c(
  "Zaccharie Risacher",
  "Alexandre Sarr",
  "Reed Sheppard",
  "Stephon Castle",
  "Ron Holland",
  "Tidjane Salaun",
  "Donovan Clingan",
  "Rob Dillingham",
  "Zach Edey",
  "Cody Williams",
  "Matas Buzelis",
  "Dalton Knecht",
  "Jared McCain",
  "Yves Missi",
  "Kel'el Ware",
  "Carlton Carrington",
  "Tristan da Silva",
  "Jaylon Tyson",
  "Kyshawn George",
  "Isaiah Collier",
  "Ryan Dunn",
  "Tyler Kolek",
  "Kyle Filipowski",
  "Baylor Scheierman"
)

rookie_names

# Adding rookie/veterans as classification:
nba_player <- nba_player %>%
  mutate(
    Rookie_Binary = ifelse(Player %in% rookie_names, 1, 0),
    Experienced_Group = ifelse(Rookie_Binary == 1, "Rookie", "Veteran")
  )
View(nba_player)
table(nba_player$Rookie_Binary)
table(nba_player$Experienced_Group)

# Create SEM data for Multi-group CFA:
cfa_data <- nba_player %>%
  select(
    Player,
    PTS, AST, FT, TOV,
    ORB, BLK, DRB,
    Rookie_Binary,
    Experienced_Group
  )

cfa_data_scaled <- cfa_data %>%
  mutate(
    across(
      c(PTS, AST, FT, TOV, ORB, BLK, DRB),
      ~ as.numeric(scale(.))
    )
  )
View(cfa_data_scaled)


#CFA model specification

model <- '

Off_inv =~ PTS + AST + FT + TOV

Interior =~ ORB + BLK + DRB

AST ~~ TOV
PTS ~~ FT
ORB ~~ BLK

'

#Configural invariance model

fit_configural <- cfa(
  model,
  data = cfa_data_scaled,
  group = "Experienced_Group",
  estimator = "MLR",
  missing = "fiml",
  meanstructure = TRUE
)

summary(
  fit_configural,
  fit.measures = TRUE,
  standardized = TRUE
)

# Check for negative variances
parameterEstimates(fit_configural) %>%
  subset(op == "~~" & lhs == rhs)

#Metric invariance model

fit_metric <- cfa(
  model,
  data = cfa_data_scaled,
  group = "Experienced_Group",
  estimator = "MLR",
  missing = "fiml",
  meanstructure = TRUE,
  group.equal = c("loadings")
)

summary(
  fit_metric,
  fit.measures = TRUE,
  standardized = TRUE
)

#Scalar invariance model

fit_scalar <- cfa(
  model,
  data = cfa_data_scaled,
  group = "Experienced_Group",
  estimator = "MLR",
  missing = "fiml",
  meanstructure = TRUE,
  group.equal = c("loadings", "intercepts")
)

summary(
  fit_scalar,
  fit.measures = TRUE,
  standardized = TRUE
)

#Residual invariance model

fit_residual <- cfa(
  model,
  data = cfa_data_scaled,
  group = "Experienced_Group",
  estimator = "MLR",
  missing = "fiml",
  meanstructure = TRUE,
  group.equal = c("loadings", "intercepts", "residuals")
)

summary(
  fit_residual,
  fit.measures = TRUE,
  standardized = TRUE
)

# Compare all models:
lavTestLRT(
  fit_configural,
  fit_metric,
  fit_scalar,
  fit_residual
)

# Make a fit-index table:
# Fit Indices table:
fit_indices <- rbind(
  Configural = fitMeasures(
    fit_configural,
    c("chisq", "df", "pvalue", "cfi", "rmsea", "srmr", "aic", "bic")
  ),
  Metric = fitMeasures(
    fit_metric,
    c("chisq", "df", "pvalue", "cfi", "rmsea", "srmr", "aic", "bic")
  ),
  Scalar = fitMeasures(
    fit_scalar,
    c("chisq", "df", "pvalue", "cfi", "rmsea", "srmr", "aic", "bic")
  ),
  Residual = fitMeasures(
    fit_residual,
    c("chisq", "df", "pvalue", "cfi", "rmsea", "srmr", "aic", "bic")
  )
)

round(fit_indices, 3)

# Test Equality of latent means:
fit_scalar_equal_means <- cfa(
  model,
  data = cfa_data_scaled,
  group = "Experienced_Group",
  estimator = "MLR",
  missing = "fiml",
  meanstructure = TRUE,
  group.equal = c("loadings", "intercepts", "means")
)

lavTestLRT(
  fit_scalar,
  fit_scalar_equal_means
)

# Extracting latent mean estimates:
pe_scalar <- parameterEstimates(fit_scalar)

latent_means <- pe_scalar %>%
  subset(
    op == "~1" &
      lhs %in% c("Off_inv", "Interior")
  ) %>%
  select(lhs, group, est, se, z, pvalue)

latent_means

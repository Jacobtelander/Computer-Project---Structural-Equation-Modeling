# Computer-Project---Structural-Equation-Modeling
Project for SEM course spring 26´. 
The objective of this project is to analyze the latent structure in baketball ability of NBA players. This is done by utilizing CFA and structural equation modeling in Rstudio. The aim is to answer the following questions: 

- Can basketball statistics be explained by offensive and defensive ability of a player?
- Can an offensive latent construct be used as predictor for a defensive latent construct
among NBA players?
- Is there a statistically significant difference in latent measurement structure between
rookies and veteran players?

## Dataset

The dataset consist of NBA player-game statistics from the 2024–25 season. It includes:

- **Player**: Name of the player.
- **Tm**: Abbreviation of the player's team.
- **Opp**: Abbreviation of the opposing team.
- **Res**: Result of the game for the player's team.
- **MP**: Minutes played, represented as a float (e.g., 23.5 = 23 minutes and 30 seconds).
- **FG**: Field goals made.
- **FGA**: Field goal attempts.
- **FG%**: Field goal percentage.
- **3P**: 3-point field goals made.
- **3PA**: 3-point field goal attempts.
- **3P%**: 3-point shooting percentage.
- **FT**: Free throws made.
- **FTAv: Free throw attempts.
- **FT%**: Free throw percentage.
- **ORB**: Offensive rebounds.
- **DR**v: Defensive rebounds.
- **TRB**: Total rebounds.
- **AST**: Assists.
- **STL**: Steals.
- **BLK**: Blocks.
- **TOV**: Turnovers.
- **PF**: Personal fouls.
- **PTS**: Total points scored.
- **GmSc**: Game Score, a metric summarizing player performance for the game.
- **Date**: Date of the game in YYYY-MM-DD format.

## Methods

Data Cleaning → removed missing values using FIML and then aggregated to player-level.

CFA & SEM → Models created with initial theorised latent construct, then adjusted for improved fit. Offensce theorized to affect defence

Model fit → Model diagnostics using CFI, TLI, RMSEA, SRMR and Chi-square.

## Results
1. NBA player performance is not adequately represented by a simple distinction between offensive and defensive ability.
2. Offensive involvement and interior presence serves as much better latent constructs than the intially proposed latent variables (Offensive and defensive ability).
3. The latent structure is similar between groups.
4. 


## Tools Used
- Rstudio
- Excel
- Overleaf

## Authors

- Jacob Telander
- Måns Conradson
- Teerth Gupta

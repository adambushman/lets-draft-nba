![Let's Draft NBA Banner](./images/lets-draft-nba-banner.png)

# Let's Draft NBA

An application for simulating the NBA draft based on industry rankings. [Give it a test drive](https://adambushman.github.io/lets-draft-nba/)!

## Description

*Let's Draft NBA* was born from observations during the 2023 NBA Draft cycle.

Everyone knew Victor Wembanyama would go #1 overall yet simulation results continued to flood the internet where he could fall lower in the top 5.

We aimed to solve this and other minor problems by orienting the logic and variance of the draft around industry expert perception.

Our logic dictates that a prospect has the range observed from experts.

Should John Doe be ranked 5 through 10 by the industry, the simulation may pick him within that range with probabilities based on the distribution of rankings (i.e. if nine industry boards rank him at 5 and one at 10, he's far more likely to be selected at 5, 6, etc)

Let's Draft NBA was built by [Adam Bushman](https://www.adambushman.dev/follow.html)

## Build Details

The application was largely build with vanila HTML, CSS, and JavaScript. Three libraries in particular, however, were relied upon heavily: 

*  Bootstrap CSS framework library for advanced styling
*  D3 JavaScript library for dynamic DOM manipulation
*  Arquero JavaScript for data transformation pipelines
*  JQuery JavaScript library for modal toggling

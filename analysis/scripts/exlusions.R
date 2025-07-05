library(tidyverse)

inference <- read.csv('../tidied_data/all_conditions/inference.csv')

# get prop correct for each subject
summary <- inference %>% group_by(subID) %>% summarise(propCorrect = mean(accuracy),
                                                       nTrial = max(trial))

# 0.52 criterion
simple_exclusion <- summary %>% filter(propCorrect < 0.52) %>% select(subID) %>% pull()

# binomial criterion
quantile <- 0.95
p <- 0.5

binom_exclusion <- summary %>% 
  mutate(pChance = qbinom(quantile, nTrial, p) / nTrial) %>%
  filter(propCorrect < pChance) %>% 
  select(subID) %>% 
  pull()

write(binom_exclusion, 'belowChanceSubs.txt')

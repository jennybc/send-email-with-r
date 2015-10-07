library(readr)
library(dplyr)

lotr <-
  read_tsv("https://raw.githubusercontent.com/jennybc/lotr/master/lotr_clean.tsv")

fotr <- lotr %>%
  filter(Film == "The Fellowship Of The Ring")

fake_dat <- fotr %>%
  group_by(Character, Race) %>%
  summarise(words = sum(Words)) %>%
  arrange(desc(words)) %>%
  ungroup() %>%
  mutate(mark = (100 * (min_rank(words) / length(words)))  %>% round) %>%
  select(name = Character, mark, Race)

email_domains <- read_csv("
  Race, domain
  Hobbit, shire
  Elf, valinor
  Wizard, maiar
  Man, gondor
  Orc, mordor
  Dwarf, erebor
  ", skip = 1)

fake_dat <- fake_dat %>%
  left_join(email_domains) %>%
  mutate(name_sans_spaces = gsub('[\\.\\s+]+', '_', fake_dat$name, perl = TRUE),
         email = paste0(tolower(name_sans_spaces), "@", domain, ".example.org")) %>%
  arrange(desc(mark))

marks <- fake_dat %>%
  select(name, mark)

write_csv(marks, file.path("..", "marks.csv"))

emails <- fake_dat %>%
  select(name, email)

write_csv(emails, file.path("..", "addresses.csv"))

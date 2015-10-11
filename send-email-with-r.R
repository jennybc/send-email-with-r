suppressPackageStartupMessages(library(gmailr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
library(readr)

addresses <- read_csv("addresses.csv")
marks <- read_csv("marks.csv")
my_dat <- left_join(marks, addresses)

this_hw <- "The Fellowship Of The Ring"
email_sender <- 'Peter Jackson <peter@tolkien.example.com>' # your Gmail address
optional_bcc <- 'Anonymous <anon@palantir.example.org>'     # for me, TA address
body <- "Hi, %s.

Your mark for %s is %s.

Thanks for participating in this film!
"

edat <- my_dat %>%
  mutate(
    To = sprintf('%s <%s>', name, email),
    Bcc = optional_bcc,
    From = email_sender,
    Subject = sprintf('Mark for %s', this_hw),
    body = sprintf(body, name, this_hw, mark)) %>%
  select(To, Bcc, From, Subject, body)
edat
write_csv(edat, "composed-emails.csv")

emails <- edat %>%
  map_rows(mime, .labels = FALSE) %>%
  rename(mime = .out)
emails <- emails$mime

## for interactive use, if credentials not cached
#gmail_auth("gmailr-tutorial.json", scope = 'compose')

sent_mail <- emails %>%
  map(send_message)
saveRDS(sent_mail,
        paste(gsub("\\s+", "_", this_hw), "sent-emails.rds", sep = "_"))

sent_mail %>%
  map_int("status_code") %>%
  unique()

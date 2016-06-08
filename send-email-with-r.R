suppressPackageStartupMessages(library(gmailr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
library(readr)

addresses <- read_csv("addresses.csv")
marks <- read_csv("marks.csv")
my_dat <- left_join(marks, addresses)

this_hw <- "The Fellowship Of The Ring"
email_sender <- 'Peter Jackson <peter@tolkien.example.org>' # your Gmail address
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
  map_n(mime)

## optional: use if you've created your own client id
use_secret_file("gmailr-tutorial.json")

safe_send_message <- safely(send_message)
sent_mail <- emails %>%
  map(safe_send_message)

saveRDS(sent_mail,
        paste(gsub("\\s+", "_", this_hw), "sent-emails.rds", sep = "_"))

errors <- sent_mail %>%
  transpose() %>%
  .$error %>%
  map_lgl(Negate(is.null))
sent_mail[errors]


-   [How to send a bunch of emails from R](#how-to-send-a-bunch-of-emails-from-r)
    -   [FAQ: Can't I "just" do this with sendmail?](#faq-cant-i-just-do-this-with-sendmail)
    -   [Prep work related to Gmail and the `gmailr` package](#prep-work-related-to-gmail-and-the-gmailr-package)
    -   [Dry run](#dry-run)
    -   [Compose and send your emails](#compose-and-send-your-emails)

How to send a bunch of emails from R
====================================

We send a fair amount of email in [STAT 545](http://stat545.com). For example, it's how we inform students of their marks on weekly homework and peer review. We use R for essentially all aspects of the course and this is no exception.

In this repo I describe our workflow, with Lord of the Rings characters playing the role of our students.

Must haves:

-   A Google account with an associated Gmail email address.
-   The [`gmailr` R package](http://cran.r-project.org/web/packages/gmailr/index.html) by Jim Hester, which wraps the Gmail API (development on [GitHub](https://github.com/jimhester/gmailr)).

Nice to haves:

-   A project in Google Developers Console to manage your use of the Gmail API. Optional but recommended once your use `gmailr` is more than casual, as mine is.
-   The [`readr`](http://cran.r-project.org/web/packages/readr/index.html), [`dplyr`](http://cran.r-project.org/web/packages/dplyr/index.html) and [`purrr`](https://cran.r-project.org/web/packages/purrr/) packages for data wrangling and iteration. "Past me" used `plyr` instead of `purrr` and you could certainly do all of this with base R if you prefer.
-   [`addresses.csv`](addresses.csv) a file containing email addresses, identified by a **key**. In our case, student names.
-   [`marks.csv`](marks.csv) a file containing the variable bits of the email you plan to send, including the same identifying **key** as above. In our case, the homework marks.
-   The script [`send-email-with-r.R`](send-email-with-r.R) that
    -   joins email addresses to marks
    -   creates valid email objects from your stuff
    -   provides your Gmail credentials
    -   sends email

### FAQ: Can't I "just" do this with sendmail?

YES, be my guest! If you can get that working quickly, I salute you -- you clearly don't need this tutorial. For everyone else, I have found this Gmail + `gmailr` approach less exasperating.

Prep work related to Gmail and the `gmailr` package
---------------------------------------------------

Verify that your Google account is mail-capable by visiting <https://mail.google.com/mail/> while logged in. If it's not, you might as well stop reading now. Or accept the offer at that link to enable Gmail or create a new mail-capable account.

Install the `gmailr` package from CRAN or the development version from GitHub (pick ONE):

``` r
install.packages("gmailr")
## OR ...
devtools::install_github("jimhester/gmailr")
```

### Create a project in Google Developers Console

If your use of `gmailr` is more than casual, you should get your own client id. Don't worry if you don't know what that means. Just do it.

I have found this works better -- or only works at all -- if I use Google Chrome versus, say, Safari. YMMV.

-   Pick a name for your project. I chose "gmailr-tutorial" for this write-up. Let's call this `PROJ-NAME` from now on.
-   Create a new project at <https://console.developers.google.com/project>.
-   Overview screen &gt; Google Apps APIs &gt; Gmail API.
    -   Enable!
-   Click "Go to Credentials" or navigate directly to Credentials.
-   You want a "client ID".
-   Yes, you will have to "Configure consent screen".
    -   The email should be pre-filled, since presumably you are signed in with the correct Google account. Enter `PROJ-NAME` as the Product name and leave everything else blank. Click Save.
-   Back to ... Create client ID. Select application type "Other". Enter `PROJ-NAME` again here for the name. Click "Create".
-   OAuth client pop up will show you your client ID and secret. You don't need to copy them -- there are better ways to get this info. Dismiss with "OK".
-   Click on the download icon at the far right of your project's OAuth 2.0 client ID listing to get a JSON file with your ID and secret. You'll get a file named something like this:

            client_secret_<LOTS OF DIGITS AND LETTERS>.apps.googleusercontent.com.json

    I rename this after the project, e.g., `PROJ-NAME.json` and move into the directory where the bulk emailing project lives.

-   *Optional* if you are using Git, add a line like this to your `.gitignore` file

            PROJ-NAME.json

-   You can add members to specific projects from Google Developers Console, allowing them to also download JSON credentials for the same project. I do that for my TAs, for example.

Dry run
-------

See [`dryrun.R`](dryrun.R) for clean code.

Load `gmailr`. *PSA: it masks several functions from `base` and `utils`, including `message()`.*

``` r
suppressPackageStartupMessages(library(gmailr))
```

**If you chose to get your own client id**, tell `gmailr` about that JSON file now. Otherwise, skip this and `gmailr` will use its own built-in client id.

``` r
use_secret_file("gmailr-tutorial.json")
```

You can force the auth process explicitly via `gmail_auth()` or simply go about your business and it will happen when needed. Let's send a test email.

``` r
test_email <- mime(
    To = "PUT_A_VALID_EMAIL_ADDRESS_THAT_YOU_CAN_CHECK_HERE",
    From = "PUT_THE_GMAIL_ADDRESS_ASSOCIATED_WITH_YOUR_GOOGLE_ACCOUNT_HERE",
    Subject = "this is just a gmailr test",
    body = "Can you hear me now?")
send_message(test_email)
```

    #> Id: 155324357156abf4
    #> To: 
    #> From: 
    #> Date: 
    #> Subject: 
    #> 

You may be presented with this question

    Use a local file to cache OAuth access credentials between R sessions?
    1: Yes
    2: No

    Selection: 

No matter what, the first time, you should get kicked into a browser to authenticate yourself and authorize the application. If you say "No", this will happen every time and is appropriate for interactive execution of your bulk emailing R code. If you say "Yes", your credentials will be cached in a file named `.httr-oauth` so the browser dance won't happen in the future. Choose this if you plan to execute your bulk emailing code non-interactively.

*Optional* if you opt for OAuth credential caching and you're using Git, add this to your `.gitignore` file. *Note: it appears that `gmailr` does this for you, but make sure it happens!*:

    .httr-oauth

Did your email get through? **Do not proceed until the answer is YES**.

If this doesn't work, running it inside a loop with typo-ridden email addresses is unlikely work any better.

Compose and send your emails
----------------------------

The hard parts are over! See [`send-email-with-r.R`](send-email-with-r.R) for clean code to compose and send email. Here's the guided tour.

The file [`addresses.csv`](addresses.csv) holds names and email addresses. The file [`marks.csv`](marks.csv) holds names and homework marks. In this case, the LoTR characters receive marks based on the number of words they spoke in the Fellowship of the Ring. Read those in and join.

``` r
suppressPackageStartupMessages(library(gmailr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
library(readr)

addresses <- read_csv("addresses.csv")
marks <- read_csv("marks.csv")
(my_dat <- left_join(marks, addresses))
#> Joining by: "name"
#> Source: local data frame [34 x 3]
#> 
#>         name  mark                         email
#>        <chr> <int>                         <chr>
#> 1    Gandalf   100     gandalf@maiar.example.org
#> 2      Bilbo    97       bilbo@shire.example.org
#> 3  Galadriel    94 galadriel@valinor.example.org
#> 4      Frodo    91       frodo@shire.example.org
#> 5    Boromir    88    boromir@gondor.example.org
#> 6    Aragorn    85    aragorn@gondor.example.org
#> 7     Elrond    79    elrond@valinor.example.org
#> 8        Sam    79         sam@shire.example.org
#> 9    Saruman    76     saruman@maiar.example.org
#> 10     Gimli    74      gimli@erebor.example.org
#> ..       ...   ...                           ...
```

Next we create a data frame where each variable is a key piece of the email, e.g. the "To" field or the body.

``` r
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
write_csv(edat, "composed-emails.csv")
```

We write this data frame to `.csv` for an easy-to-read record of the composed emails. You will never regret saving such small, easy-to-read things.

We use the `gmailr::mime()` function to convert each row of this data frame into a MIME-formatted message object. We use `purrr::pmap()` to generate the list of mime objects, one per row of the input data frame. I present commented-out `plyr` code, for historical interest. If you want base R, you're on your own.

``` r
emails <- edat %>%
  pmap(mime)
str(emails, max.level = 2, list.len = 2)
#> List of 34
#>  $ :List of 4
#>   ..$ parts : list()
#>   ..$ header:List of 6
#>   .. .. [list output truncated]
#>   .. [list output truncated]
#>   ..- attr(*, "class")= chr "mime"
#>  $ :List of 4
#>   ..$ parts : list()
#>   ..$ header:List of 6
#>   .. .. [list output truncated]
#>   .. [list output truncated]
#>   ..- attr(*, "class")= chr "mime"
#>   [list output truncated]

## plyr code to do similar: Option A
# emails <- plyr::dlply(edat, ~ To, function(x) mime(
#   To = x$To,
#   Bcc = x$Bcc,
#   From = x$From,
#   Subject = x$Subject,
#   body = x$body))

## plyr code to do similar: Option B
# emails <- plyr::alply(edat, 1, function(x) mime(
#   To = x$To,
#   Bcc = x$Bcc,
#   From = x$From,
#   Subject = x$Subject,
#   body = x$body))
```

**If you chose to get your own client id**, tell `gmailr` about that JSON file now. Otherwise, skip this and `gmailr` will use its own built-in client id.

``` r
use_secret_file("gmailr-tutorial.json")
```

If you've cached your OAuth credentials, sending mail should "just work", though you might see something about refreshing your token. Otherwise, you can expect to do the OAuth browser dance when executing the next chunk.

Send your emails!

-   I choose to create a "safe" version of `send_message()` with `purrr::safely()`, so no single failure can derail my bulk emailing effort in the middle.
-   `purrr::map()` iterates over all the MIME objects stored in `emails.`
-   Always retain the return value, for inspection and writing to file.

``` r
safe_send_message <- safely(send_message)
sent_mail <- emails %>% 
  map(safe_send_message)

saveRDS(sent_mail,
        paste(gsub("\\s+", "_", this_hw), "sent-emails.rds", sep = "_"))
```

How does this `safely()` thing work? In a hidden chunk, I've used code like the above to attempt to send 3 emails. The one in the middle intentionally has a nonsensical "To" field and fails. Here's how I inspect the result and access the error.

``` r
errors <- sent_mail %>% 
  transpose() %>% 
  .$error %>% 
  map_lgl(Negate(is.null))
sent_mail[errors]
#> [[1]]
#> [[1]]$result
#> NULL
#> 
#> [[1]]$error
#> <condition in gmailr_POST(c("messages", "send"), user_id, class = "gmail_message",     query = list(uploadType = type), body = jsonlite::toJSON(auto_unbox = TRUE,         null = "null", c(threadId = thread_id, list(raw = base64url_encode(mail)))),     add_headers(`Content-Type` = "application/json")): Gmail API error: 400
#>   Invalid to header
#> >
```

The end.

### session info

``` r
devtools::session_info()
#> Session info --------------------------------------------------------------
#>  setting  value                       
#>  version  R version 3.3.0 (2016-05-03)
#>  system   x86_64, darwin13.4.0        
#>  ui       X11                         
#>  language (EN)                        
#>  collate  en_CA.UTF-8                 
#>  tz       America/Los_Angeles         
#>  date     2016-06-08
#> Packages ------------------------------------------------------------------
#>  package    * version     date       source                            
#>  assertthat   0.1         2013-12-06 CRAN (R 3.2.0)                    
#>  base64enc    0.1-3       2015-07-28 CRAN (R 3.2.0)                    
#>  crayon       1.3.1       2015-07-13 CRAN (R 3.2.0)                    
#>  curl         0.9.7       2016-04-10 CRAN (R 3.2.4)                    
#>  DBI          0.4-1       2016-05-08 cran (@0.4-1)                     
#>  devtools     1.11.1.9000 2016-06-04 Github (hadley/devtools@ca34be3)  
#>  digest       0.6.9       2016-01-08 CRAN (R 3.2.3)                    
#>  dplyr      * 0.4.3.9001  2016-05-10 Github (hadley/dplyr@2aeb05f)     
#>  evaluate     0.9         2016-04-29 CRAN (R 3.3.0)                    
#>  formatR      1.4         2016-05-09 CRAN (R 3.3.0)                    
#>  gmailr     * 0.7.1.9000  2016-06-08 github (jimhester/gmailr)         
#>  htmltools    0.3.5       2016-03-21 CRAN (R 3.2.4)                    
#>  httr         1.1.0.9000  2016-04-01 Github (hadley/httr@f2c3c4d)      
#>  jsonlite     0.9.21      2016-06-04 cran (@0.9.21)                    
#>  knitr        1.13.1      2016-06-04 github (yihui/knitr)              
#>  lazyeval     0.1.10.9000 2016-04-28 Github (hadley/lazyeval@bce211b)  
#>  magrittr     1.5         2014-11-22 CRAN (R 3.2.0)                    
#>  memoise      1.0.0       2016-01-29 CRAN (R 3.2.3)                    
#>  openssl      0.9.4       2016-05-25 cran (@0.9.4)                     
#>  purrr      * 0.2.1.9000  2016-04-25 Github (hadley/purrr@9534c29)     
#>  R6           2.1.2       2016-01-26 CRAN (R 3.2.3)                    
#>  Rcpp         0.12.5      2016-05-14 cran (@0.12.5)                    
#>  readr      * 0.2.2       2015-10-22 CRAN (R 3.2.0)                    
#>  rmarkdown    0.9.6.14    2016-06-03 Github (rstudio/rmarkdown@3456ed7)
#>  stringi      1.1.1       2016-05-27 cran (@1.1.1)                     
#>  stringr      1.0.0       2015-04-30 CRAN (R 3.2.0)                    
#>  tibble       1.0-5       2016-05-18 Github (hadley/tibble@19235d2)    
#>  withr        1.0.1       2016-02-04 CRAN (R 3.2.3)                    
#>  yaml         2.1.13      2014-06-12 CRAN (R 3.2.0)
```

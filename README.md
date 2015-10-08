How to send a bunch of emails from R
====================================

We send a fair amount of email in [STAT 545](http://stat545-ubc.github.io). For example, it's how we inform students of their marks on weekly homework and peer review. We use R for essentially all aspects of the course and this is no exception.

In this repo I describe our workflow, with Lord of the Rings characters playing the role of our students.

Key pieces:

-   a Google account with an associated Gmail email address
-   a project in Google Developers Console to manage your use of the Gmail API
-   the [`gmailr` R package](http://cran.r-project.org/web/packages/gmailr/index.html) by Jim Hester, which wraps the Gmail API (development on [GitHub](https://github.com/jimhester/gmailr))
-   the [`readr`](http://cran.r-project.org/web/packages/readr/index.html), [`dplyr`](http://cran.r-project.org/web/packages/dplyr/index.html) and [`purrr`](https://cran.r-project.org/web/packages/purrr/) packages for data wrangling and iteration (in the past, I've used `plyr` instead of `purrr` and you could certainly do all of this with base R if you prefer)
-   [`addresses.csv`](addresses.csv) a file containing email addresses, identified by a **key**. In our case, student names.
-   [`marks.csv`](marks.csv) a file containing the variable bits of the email you plan to send, including the same identifying **key** as above. In our case, the homework marks.
-   the script [`send-email-with-r.r`](send-email-with-r.r) that
    -   joins email addresses to marks
    -   creates valid email objects from your stuff
    -   provides your Gmail credentials
    -   sends email

#### FAQ: Can't I "just" do this with sendmail?

YES, be my guest! If you can get that working quickly, I salute you -- you clearly don't need this tutorial. For everyone else, I have found this Gmail + `gmailr` approach less exasperating.

Prep work related to Gmail and the `gmailr` package
---------------------------------------------------

Install the `gmailr` package from CRAN or the development version from GitHub (pick ONE):

``` r
install.packages("gmailr")
## OR ...
devtools::install_github("jimhester/gmailr")
```

I'm using the CRAN version.

Gmail set-up inspired by the helpful [`gmailr` vignette](http://cran.r-project.org/web/packages/gmailr/vignettes/sending_messages.html)

-   Create a new project at <https://console.developers.google.com/project>. I named mine "gmailr-tutorial" for this write-up.
-   Navigate to `APIs & auth > APIs > Google Apps APIs > Gmail API`.
    -   Click "Enable API".
-   Navigate to `APIs & auth > Credentials > Add credentials`.
    -   Select "OAuth 2.0 client ID".
    -   Expect this message: "To create an OAuth client ID, you must first set a product name on the consent screen". Click "Configure consent screen". The email should be pre-filled, since presumably you are signed in with the correct Google account. I entered "gmailr-tutorial" as the Product name and left everything else blank. Click Save.
    -   Back to ... Create client ID. Select application type "Other". I entered "gmailr-tutorial" again here for the name. Click "Create".
    -   OAuth client pop up will show you your client ID and secret. You don't need to copy them -- there are better ways to get this info.
    -   In theory, you can use the download icon at the far right of your project's OAuth 2.0 client ID listing to get a JSON file with your ID and secret. In the past, this has just worked for me, but right now I can only do this from Chrome, but not Safari. :frowning: [This stackoverflow thread](http://stackoverflow.com/questions/30894950/client-secret-json-is-empty-upon-download-from-google-developer-site) suggests others have had similar problems in the recent past. Find a browser that works for you and you'll get a file named something like this:

            client_secret_<LOTS OF DIGITS AND LETTERS>.apps.googleusercontent.com.json

        I renamed this after the project, e.g., `gmailr-tutorial.json` and moved into the directory where the bulk emailing project lives.

    -   *Optional* if you are using Git, add a line like this to your `.gitignore` file

            gmailr-tutorial.json

Let's do a dry run before we try to send real emails. See [`dryrun.R`](dryrun.R) for code.

Load `gmailr`, call `gmail_auth()` function with the credentials stored in JSON, and declare your intent to compose an email.

``` r
suppressPackageStartupMessages(library(gmailr))
gmail_auth("gmailr-tutorial.json", scope = 'compose')
```

You may be presented with this question

    Use a local file to cache OAuth access credentials between R sessions?
    1: Yes
    2: No

    Selection: 

No matter what, the first time, you should get kicked into a browser to authorize the application. If you say "No", this will happen every time and is appropriate for interactive execution of your bulk emailing R code. If you say "Yes", your credentials will be cached in a file named `.httr-oauth` so the browser dance won't happen in the future. Choose this if you plan to execute your bulk emailing code non-interactively.

*Optional* if you opt for OAuth credential caching and you're using Git, add this to your `.gitignore` file. *Note: it appears that `gmailr` does this for you, but make sure it happens!*:

    .httr-oauth

Use the code in [`dryrun.r`](dryrun.r) to send a test email:

``` r
test_email <- mime(
    To = "PUT_A_VALID_EMAIL_ADDRESS_THAT_YOU_CAN_CHECK_HERE",
    From = "PUT_THE_GMAIL_ADDRESS_ASSOCIATED_WITH_YOUR_GOOGLE_ACCOUNT_HERE",
    Subject = "this is just a gmailr test",
    body = "Can you hear me now?")
ret_val <- send_message(test_email)
ret_val$status_code 
```

    ## [1] 200

Is the status code 200? Did your email get through? **Do not proceed until the answer is YES to both questions**.

If this doesn't work, running it inside a loop with typo-ridden email addresses is unlikely work any better.

BTW you can add members to your project from "Permissions" in Google Developers Console, allowing them to also download JSON credentials for the same project. I do that for my TAs, for example.

Compose and send your emails
----------------------------

The hard parts are over! See [`send-email-with-r.R`](send-email-with-r.R) for clean code to compose and send email. Here's the guided tour.

The file [`addresses.csv`](addresses.csv) holds names and email addresses. The file [`marks.csv`](marks.csv) holds names and homework marks. (In this case, the LoTR characters receive marks based on the number of words they spoke in the Fellowship of the Ring.) Read those in and join.

``` r
suppressPackageStartupMessages(library(gmailr))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
library(readr)

addresses <- read_csv("addresses.csv")
marks <- read_csv("marks.csv")
my_dat <- left_join(marks, addresses)
```

    ## Joining by: "name"

``` r
my_dat
```

    ## Source: local data frame [34 x 3]
    ## 
    ##         name  mark                         email
    ##        (chr) (int)                         (chr)
    ## 1    Gandalf   100     gandalf@maiar.example.org
    ## 2      Bilbo    97       bilbo@shire.example.org
    ## 3  Galadriel    94 galadriel@valinor.example.org
    ## 4      Frodo    91       frodo@shire.example.org
    ## 5    Boromir    88    boromir@gondor.example.org
    ## 6    Aragorn    85    aragorn@gondor.example.org
    ## 7     Elrond    79    elrond@valinor.example.org
    ## 8        Sam    79         sam@shire.example.org
    ## 9    Saruman    76     saruman@maiar.example.org
    ## 10     Gimli    74      gimli@erebor.example.org
    ## ..       ...   ...                           ...

Next we create a data.frame where each variable is a key piece of the email, e.g. the "To" field or the body.

``` r
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
```

    ## Source: local data frame [34 x 5]
    ## 
    ##                                           To
    ##                                        (chr)
    ## 1        Gandalf <gandalf@maiar.example.org>
    ## 2            Bilbo <bilbo@shire.example.org>
    ## 3  Galadriel <galadriel@valinor.example.org>
    ## 4            Frodo <frodo@shire.example.org>
    ## 5       Boromir <boromir@gondor.example.org>
    ## 6       Aragorn <aragorn@gondor.example.org>
    ## 7        Elrond <elrond@valinor.example.org>
    ## 8                Sam <sam@shire.example.org>
    ## 9        Saruman <saruman@maiar.example.org>
    ## 10          Gimli <gimli@erebor.example.org>
    ## ..                                       ...
    ## Variables not shown: Bcc (chr), From (chr), Subject (chr), body (chr)

``` r
write_csv(edat, "composed-emails.csv")
```

We write this data.frame to `.csv` for an easy-to-read record of the composed emails. You will never regret saving such small, easy-to-read things.

If you've cached your OAuth credentials, sending mail should "just work", though you might see something about refreshing your token. If you have not cached, you need to authenticate yourself explicitly with `gmail_auth()` and do the browser dance again.

``` r
gmail_auth("gmailr-tutorial.json", scope = 'compose')
```

We use the `gmailr::mime()` function to convert each row of this data.frame into a MIME-formatted message object. We use `purrr` to generate the list of mime objects, one per row of the input data.frame. FYI I'm making myself use `purrr` here in order to learn it and see if it can replace `plyr`. I present commented-out `plyr` code, for kicks. If you want base R, you're on your own.

``` r
emails <- edat %>%
  map_rows(lift(mime), .labels = FALSE) %>% 
  ## wonder if can name the new variable something other than '.out'?
  rename(mime = .out)
str(emails, max.level = 2, list.len = 2)
```

    ## Classes 'tbl_df' and 'data.frame':   34 obs. of  2 variables:
    ##  $ mime:List of 34
    ##   ..$ :List of 4
    ##   .. .. [list output truncated]
    ##   .. ..- attr(*, "class")= chr "mime"
    ##   ..$ :List of 4
    ##   .. .. [list output truncated]
    ##   .. ..- attr(*, "class")= chr "mime"
    ##   .. [list output truncated]
    ##  $     : NULL

``` r
## why do I get an unnamed 2nd variable that is NULL?
## actually I just want the list of mime objects, not a data.frame
emails <- emails$mime

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

Now send your emails and save the return value in case you need to do forensics later. The return value will be a list of lists, so dump it into an `.rds` file ... best case, you'll never need to look at it.

``` r
sent_mail <- emails %>% 
  map(send_message)
## plyr approach
#sent_mail <- plyr::llply(emails, send_message, .progress = 'text')
saveRDS(sent_mail,
        paste(gsub("\\s+", "_", this_hw), "sent-emails.rds", sep = "_"))
```

Let's take a look at the status codes. Hopefully they're all 200?

``` r
sent_mail %>%
  map_int("status_code") %>% 
  unique()
```

    ## [1] 200

The end.

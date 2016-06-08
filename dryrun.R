library(gmailr)

## edit line below to reflect YOUR json credential filename
use_secret_file("gmailr-tutorial.json")

## edit below with email addresses from your life
test_email <- mime(
  To = "PUT_A_VALID_EMAIL_ADDRESS_THAT_YOU_CAN_CHECK_HERE",
  From = "PUT_THE_GMAIL_ADDRESS_ASSOCIATED_WITH_YOUR_GOOGLE_ACCOUNT_HERE",
  Subject = "this is just a gmailr test",
  body = "Can you hear me now?")

send_message(test_email)

## verify that the email arrives succesfully!

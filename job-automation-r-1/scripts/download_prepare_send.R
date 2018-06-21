require(magrittr)
require(jsonlite)
require(rmarkdown)
require(mailR)
require(readr)
require(ggplot2)


### settings

setwd("/scripts")
source("config", encoding = "UTF-8")

### download data && prepare attachments

fn <- paste0("tmp/prices_", format(Sys.Date(), '%Y_%m_%d'), ".csv")
dir.create("tmp", showWarnings = FALSE)

prices <- paste0('http://api.nbp.pl/api/cenyzlota/',
       format(Sys.Date(), '%Y'), '-01-01/', 
       format(Sys.Date(), '%Y-%m-%d'),
       '?format=json') %>%
  fromJSON %>%
  set_colnames(c('date', 'price')) %T>%
  write.csv2(fn, row.names = FALSE)

# plot
png(file.path(getwd(), "tmp/", "plot.png")); ggplot(prices, aes(as.Date(date), price)) + geom_point() + xlab("date") + ggtitle(paste0("Gold prices in ", format(Sys.Date(), "%Y"))); dev.off()

### prepare e-mail

render(input         = "template.Rmd",
       output_file   = "email.html",
       output_format = "html_document",
       params        = list(prices = prices,
                            is_html = TRUE),
       encoding      = "utf-8")
	   
# trick: images in e-mail
read_file("email.html") %>%
  gsub("%%plot%%", '<img src="tmp/plot.png">', ., fixed = TRUE) %>%
  write_file("email.html")

# docx attachment
render(input         = "template.Rmd",
       output_file   = "report.docx",
       output_format = "word_document",
       params        = list(prices = prices,
                            is_html = FALSE),
       encoding      = "utf-8")

### send e-mail

email <- send.mail(from         = email_from,
                   to           = email_to,
                   subject      = paste0("NBP > GOLD PRICES > ", format(Sys.Date(), '%Y-%m-%d')),
                   body         = "email.html",
                   encoding     = "utf-8",
                   html         = TRUE,
                   smtp         = smtp_config,
                   inline       = TRUE,
                   attach.files = c(fn, "report.docx"),
                   authenticate = TRUE,
                   send         = FALSE,
				   debug        = TRUE)

e <- try(email$send())

### cleaning

unlink("tmp", recursive = TRUE)
unlink("email.html", recursive = TRUE)
unlink("report.docx", recursive = TRUE)

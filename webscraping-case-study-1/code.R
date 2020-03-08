# packages
require(magrittr) # pipe
require(rvest) # web scraping
require(stringi) # text cleaning
require(readr) # file reading
require(magick) # image processing 
require(tesseract) # OCR
require(googledrive) # Google Drive

# download webpage
s <- paste0( 
  'https://www.analizy.pl/',
  'fundusze/fundusze-inwestycyjne/notowania') %>%
  html_session

# data extraction
notowania <- s %>%
  # noteTable is the only element on the page
  html_node("#noteTable") %>% 
  # the header has two levels
  html_table(header = TRUE) %>% 
  .[,-1] %>% 
  set_colnames(.[1,]) %>% 
  # the first column is omitted (its image)
  .[-1,] %T>% 
  # summary
  str

# get links
notowania$`j.u. netto` <- s %>%
  html_nodes("tbody img[alt*='kurs']") %>%
  html_attr("src") %>%
  paste0("https://www.analizy.pl", .)

# tesseract

# OCR settings
engine <-
  tesseract(options = 
    list(tessedit_char_whitelist = " 0123456789,.",
         tessedit_char_blacklist = "!?@#$%&*()<>_-+=/:;'\"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\n\t\r",
         classify_bln_numeric_mode = "1"))

# text cleaning
text_clearing <- function(x) {
  x %>%
    stri_replace_all_regex("[ \n]", "") %>%
    stri_replace_all_regex("[,]+", ".") %>%
    stri_extract_first_regex('[0-9]+[//.]{0,1}[0-9]{0,2}') %>%
    as.numeric %>%
    format(2)
}

# sample conversion
notowania[['j.u. netto']][1] %>%
  image_read %>%
  ocr(engine) %>%
  text_clearing

# google drive

# function
OCRbyGoogleDrive <- function(urls) {
  # download images
  imgs <- list()
  for (url in urls) {
    imgs %<>%
      append(list(list(url = url,
                       fn  = tempfile())))
  }
  lapply(imgs, function(x)
    {image_read(x$url) %>%
      image_write(x$fn, format = "png")})

  # send images to Google Drive
  gd_imgs <-
    lapply(imgs, function(x)
      {drive_upload(x$fn, type = "png")})

  # convert to Google documents
  gd_imgs_cp <-
    lapply(gd_imgs, function(x)
      {drive_cp(as_id(x$id),
                mime_type = drive_mime_type("document"))})

  # write as txt files
  txt_files <-
    lapply(gd_imgs_cp, function(x)
      {drive_download(as_id(x$id), type = "txt")})

  # text cleaning
  res <-
    sapply(txt_files, function(x)
      {read_file(x$local_path)}) %>%
    stri_replace_all_regex("[ ,\\.]", "") %>%
    stri_extract_last_regex("[0-9]+") %>%
    as.numeric %>%
    divide_by(100)

  # remove temporary files
  imgs %>% lapply(function(x)
    unlink(x$fn))
  txt_files %>% lapply(function(x)
    unlink(x$local_path))
  gd_imgs %>% lapply(function(x)
    drive_rm(as_id(x$id)))
  gd_imgs_cp %>% lapply(function(x)
    drive_rm(as_id(x$id)))

  return(cbind(urls, res))
}

# sample conversion
OCRbyGoogleDrive(notowania[['j.u. netto']][1]) # google authentication is needed

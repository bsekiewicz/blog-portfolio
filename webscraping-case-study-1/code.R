require(magrittr) # pipe
require(rvest) # webscraping
require(stringi) # text cleaning
require(readr) # file reading
require(magick) #  image processing 
require(tesseract) # OCR
require(googledrive) # gdrive API


# download data

s <- paste0( 
  'https://www.analizy.pl/',
  'fundusze/fundusze-inwestycyjne/notowania') %>%
  html_session

notowania <- s %>%
  html_node("#noteTable") %>% 
  # header has two levels
  html_table(header = TRUE) %>% 
  .[,-1] %>% 
  set_colnames(.[1,]) %>% 
  # first column is ommited (its image)
  .[-1,] %T>% 
  # show summary
  str

# get links
notowania$`j.u. netto` <- s %>%
  html_nodes("tbody img[alt*='kurs']") %>%
  html_attr("src") %>%
  paste0("https://www.analizy.pl", .)

# tesseract

# engine configuration
engine <-
  tesseract(options =
              list(tessedit_char_whitelist = " 0123456789,.",
                   tessedit_char_blacklist = "!?@#$%&*()<>_-+=/:;'\"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\n\t\r",
                   classify_bln_numeric_mode = "1"))

# sample results
notowania[['j.u. netto']][1] %>%
  image_read %>%
  # trial and error
  image_resize("130") %>%
  ocr(engine) %>%
  stringi::stri_replace_all_regex("[ \n]", "") %>%
  as.numeric

# google drive

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
      image_resize("130") %>%
      image_write(x$fn, format = "png")})
  
  # send images to google drive
  gd_imgs <-
    lapply(imgs, function(x)
    {drive_upload(x$fn, type = "png")})
  
  # convert to google documents
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
    {readr::read_file(x$local_path)}) %>%
    stringi::stri_replace_all_regex("[ ,\\.]", "") %>%
    stringi::stri_extract_last_regex("[0-9]+") %>%
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

# sample results

# google authentication is needed
OCRbyGoogleDrive(notowania[['j.u. netto']][1])

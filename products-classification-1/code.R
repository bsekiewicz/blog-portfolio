require(magrittr)
require(tm)
require(dplyr)
require(stopwords)
require(stringi)


data <- read.csv2("allegro-sports-shoes.csv", 
                  stringsAsFactors = FALSE,
                  header = TRUE) %>% 
  extract2(1)

# clean data

data %<>% tolower %>% trimws
data %<>% sapply(stri_replace_all_regex, ' ([0-9]+[^ ]{0,} )+', ' ')
data %<>% sapply(stri_replace_all_regex, '^[0-9]+[^ ]{0,} ', ' ')
data %<>% sapply(stri_replace_all_regex, ' [0-9]+[^ ]{0,}$', ' ')
data <- tm::Corpus(VectorSource(data))
data <- tm::tm_map(data, removePunctuation)
data <- tm::tm_map(data, removeWords, stopwords("polish", 'stopwords-iso'))

# frequency table

freqTable = data %>% 
  lapply(termFreq) %>% 
  do.call(bind_rows, .)

# perp table

freqTable.colsum = colSums(freqTable, na.rm = TRUE)
cols_to_remove = (freqTable.colsum >= (length(freqTable.colsum) - 5)) | (freqTable.colsum <= 5)
if (length(cols_to_remove) > 0) {
  freqTable = freqTable[, !cols_to_remove]
}

cols_to_remove = colnames(freqTable)[sapply(colnames(freqTable), function(x) nchar(x)) < 3]
if (length(cols_to_remove) > 0) {
  freqTable = freqTable[, !cols_to_remove]
}

check_perp <- function(data, term1, term2, threshold = 5) {
  vec1 = if_else(is.na(data[[term1]]), 0, 1)
  vec2 = if_else(is.na(data[[term2]]), 0, 1)
  s = sum(vec1 * vec2, na.rm = TRUE)
  return(list(is_perp = if_else(s <= threshold, TRUE, FALSE),
              distance = s,
              term1 = term1,
              term2 = term2,
              size = sum(vec1) + sum(vec2),
              term1_size = sum(vec1),
              term2_size = sum(vec2)))
}

tmp <- data.frame(stringsAsFactors = FALSE)
all_2_substets =
  seq_along(colnames(freqTable)) %>%
  combn(2) %>%
  apply(2, list)
for (i in all_2_substets) {
  s <- check_perp(freqTable, 
                  colnames(freqTable)[i[[1]][1]],
                  colnames(freqTable)[i[[1]][2]])
  
  tmp %<>% rbind(as.data.frame(s, stringsAsFactors = FALSE))
}
tmp %<>% dplyr::filter(is_perp) %>% 
  arrange(desc(size))
tmp %<>% distinct()

# find perp set

curr_set = c(tmp$term1[1], tmp$term2[1])

repeat { 
  t <- tmp %>% dplyr::filter(!((term1 %in% curr_set) & (term2 %in% curr_set)))
  
  conn_tt = list()
  for (x in curr_set) {
    tt = t %>% dplyr::filter(term1 == x | term2 == x)
    tt = setdiff(c(tt$term1, tt$term2), x) %>% unique
    conn_tt %<>% append(list(tt))
  }
  conn =intersect(conn_tt[[1]], conn_tt[[2]])
  for (i in 2:length(conn_tt)) {
    conn = intersect(conn, conn_tt[[i]])
  }

  x1 = t %>% dplyr::filter(term1 %in% conn) %>% 
    arrange(desc(term1_size)) %>%
    .[1,c('term1_size','term1')]
  
  x2 = t %>% dplyr::filter(term2 %in% conn) %>% 
    arrange(desc(term2_size)) %>%
    .[1,c('term2_size','term2')]
  
  if (x1$term1_size > x2$term2_size) {
    new_term = x1$term1
  } else {
    new_term = x2$term2
  }
  
  curr_set = c(curr_set, new_term)
  
  size = tmp %>% dplyr::filter(term1 %in% curr_set, term2 %in% curr_set) %>%
    extract2('size') %>% sum(.)/((length(curr_set)-1)*nrow(freqTable))
  
  print(paste0(new_term, ': ', size))
  
  if (size > 0.95) {
    break
  }
}
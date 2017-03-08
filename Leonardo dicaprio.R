## Set up

library(TMDb)
library(jsonlite)
library(stringi)
library(dplyr)

api_key <- '837ef765505a115040182cde97a23fdc'

## Leo info

search_person(api_key, 'Leonardo DiCaprio')
person_tmdb(api_key, 6193)

leoFilms <- person_movie_credits(api_key, 6193)$cast
leoFilms <- leoFilms[leoFilms$character != "Himself",]
leoFilms <- leoFilms[leoFilms$character != "Narrator",]
leoFilms <- leoFilms[leoFilms$character != "",]
leoFilms <- leoFilms[!is.na(leoFilms$release_date),]

ids <- leoFilms$id
titles <- leoFilms$title

## Find cast for all Leo films

castNames <- c()
castIDs <- c()
filmTitle <- c()
filmID <- c()

for(i in 1:length(ids)){
  x <- ids[i]
  results <- movie_credits(api_key, x)
  
  n <- length(results$cast$name)
  castNames <- c(castNames, results$cast$name)
  castIDs <- c(castIDs, results$cast$id)
  filmTitle <- c(filmTitle, rep(titles[i], n))
  filmID <- c(filmID, rep(ids[i], n))
  
  Sys.sleep(0.25)
}

data <- data.frame(cbind(castNames, castIDs, filmTitle, filmID))
names(data) <- c("Name", "ActorID", "Film", "FilmID")

dataJSON <- data[, "Name", drop = FALSE]
dataJSON$Group <- rep(1, dim(dataJSON)[1])
names(dataJSON) <- c("id", "group")

stri_write_lines(toJSON(dataJSON, pretty = TRUE), 'nodes.json')


## Links between cast members

source <- c()
target <- c()
value <- c()

uniqueNames <- unique(castNames)
uniqueIDs <- unique(castIDs)

for(i in 1:length(uniqueNames)){
  actor <- uniqueNames[i]

  y <- data$Film[data$Name == actor]
  subset <- data[data$Film %in% y, ]
  table <- table(subset$Name)[table(subset$Name) > 0]
  
  n <- length(names(table))
  target <- c(target, names(table))
  value <- c(value, as.vector(table))
  source <- c(source, rep(actor, n))
}

df <- data.frame(cbind(source, target, value))

df.sort <- t(apply(df, 1, sort))
df.dedupe <- as.data.frame(df.sort[!duplicated(df.sort),])
names(df.dedupe) <- c("value", "source", "target")
df.dedupe$value <- as.numeric(df.dedupe$value)
head(df.dedupe)

stri_write_lines(toJSON(df.dedupe, pretty = TRUE), 'edges.json')

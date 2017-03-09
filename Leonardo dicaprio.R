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

uniqueNames <- unique(castNames)
uniqueIDs <- unique(castIDs)
uniqueFilms <- unique(filmTitle)

dataJSON <- data.frame(c(uniqueNames, uniqueFilms)) 
dataJSON$Group <- rep(1, length(dataJSON))
names(dataJSON) <- c("id", "group")

stri_write_lines(toJSON(dataJSON, pretty = TRUE), 'nodes.json')


## Links between cast and films

source <- c()
target <- c()
value <- c()

for(i in 1:length(uniqueFilms)){
  film <- uniqueFilms[i]

  actorsInFilm <- as.character(data$Name[data$Film == film])

  n <- length(actorsInFilm)
  source <- c(source, rep(film, n))
  target <- c(target, actorsInFilm)
  value <- c(value, rep(1, n))
}

links <- data.frame(cbind(source, target, value))
links$value <- as.numeric(links$value)

#df.sort <- t(apply(df, 1, sort))
#df.dedupe <- as.data.frame(df.sort[!duplicated(df.sort),])
#names(df.dedupe) <- c("value", "source", "target")
#df.dedupe$value <- as.numeric(df.dedupe$value)
#head(df.dedupe)

stri_write_lines(toJSON(links, pretty = TRUE), 'edges.json')

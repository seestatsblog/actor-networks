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

## Count how many times actor features in film

count <- data.frame(count(data, 'Name'))

for(i in 1:dim(data)[1]){
  actor <- data$Name[i]
  data$Count[i] <- count$freq[which(count$Name == actor)]
}

## Make actor nodes

actorNodes <- as.character(unique(data$Name[data$Count > 1]))
actorNodesSize <- c()
for(i in 1:length(actorNodes)){
  a <- actorNodes[i]
  actorNodesSize[i] <- data$Count[data$Name == a][1]
}

## Make films nodes

filmNodes <- as.character(unique(data$Film))
filmNodesSize <- c()
for(i in 1:length(filmNodes)){
  b <- filmNodes[i]
  sub <- data[data$Film == b,]
  filmNodesSize[i] <- sum(sub$Count[sub$Count == 1])
}

## Combine nodes data

nodes <- data.frame(cbind(c(actorNodes, filmNodes), c(actorNodesSize, filmNodesSize)))
names(nodes) <- c("id", "size")
nodes$group[nodes$id == 'Leonardo DiCaprio'] <- 1
nodes$group[2:length(actorNodes)] <- rep(2, length(actorNodes) - 1)
nodes$group[(length(actorNodes) + 1):(length(actorNodes) + length(filmNodes))] <- rep(3, length(filmNodes)) 

stri_write_lines(toJSON(nodes, pretty = TRUE), 'nodes.json')


## Links between cast and films

source <- c()
target <- c()
value <- c()

for(i in 1:length(actorNodes)){
  actor <- actorNodes[i]
  
  actorFilms <- as.character(data$Film[data$Name == actor])
  
  n <- length(actorFilms)
  source <- c(source, rep(actor, n))
  target <- c(target, actorFilms)
  value <- c(value, rep(1, n))
}

links <- data.frame(cbind(source, target, value))
links$value <- as.numeric(links$value)

stri_write_lines(toJSON(links, pretty = TRUE), 'edges.json')

## Set up

library(TMDb)
api_key <- '837ef765505a115040182cde97a23fdc'

## Leo info

search_person(api_key, 'Leonardo DiCaprio')
person_tmdb(api_key, 6193)
leoFilms <- person_movie_credits(api_key, 6193)$cast
ids <- leoFilms$id

## Find cast for all Leo films

names <- rep(NA, length(ids))
castIDs <- rep(NA, length(ids))

for(i in 1:length(ids)){
  x <- ids[i]
  results <- movie_credits(api_key, x)
  names[i] <- paste(results$cast$name, collapse = ", ")
  castIDs[i] <- paste(results$cast$id, collapse = ", ")
  
  Sys.sleep(0.25)
}

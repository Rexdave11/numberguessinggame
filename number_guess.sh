#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read -r USERNAME
ESCAPED_USERNAME=${USERNAME//\'/\'\'}
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$ESCAPED_USERNAME';")

if [[ -z $USER_ID ]]; then
  $PSQL "INSERT INTO users(username) VALUES('$ESCAPED_USERNAME');" > /dev/null
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$ESCAPED_USERNAME';")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  GAME_STATS=$($PSQL "SELECT COUNT(*), COALESCE(MIN(number_of_guesses), 0) FROM games WHERE user_id=$USER_ID;")
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$GAME_STATS"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0
echo "Guess the secret number between 1 and 1000:"

while true; do
  read -r GUESS
  ((NUMBER_OF_GUESSES++))

  if [[ ! $GUESS =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  elif [[ $GUESS == -* ]]; then
    echo "It's higher than that, guess again:"
  elif (( 10#$GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  elif (( 10#$GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    $PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES);" > /dev/null
    break
  fi
done
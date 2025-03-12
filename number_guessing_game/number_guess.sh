#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

get_user_info() {
  echo "Enter your username:"
  read USERNAME

  MAX_LENGTH=22
  USERNAME_LENGTH=${#USERNAME}
  if [[ $USERNAME_LENGTH -gt $MAX_LENGTH ]]; then
    echo "Error: Username cannot exceed $MAX_LENGTH characters. Please enter a shorter username."
    exit 1
  fi

  USER_INFO=$($PSQL "SELECT u.user_id, COUNT(g.game_id) AS games_played, COALESCE(MIN(g.number_of_guesses), 0) AS best_game FROM scores u LEFT JOIN games g ON u.user_id = g.user_id WHERE u.username = '$USERNAME' GROUP BY u.user_id")

  if [[ -z $USER_INFO ]]; then
  echo -e "Welcome, $USERNAME! It looks like this is your first time here.\n"
  INSERT_RESULT=$($PSQL "INSERT INTO scores (username) VALUES ('$USERNAME') RETURNING user_id")
  USER_ID=$(echo $INSERT_RESULT | xargs)
  GAMES_PLAYED=0
  BEST_GAME=0
else
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

}

start_game() {
  SECRET_NUMBER=$((RANDOM % 1000 + 1))
  GUESS_COUNT=0

  echo "Guess the secret number between 1 and 1000:"
  read USER_GUESS

  while [[ $USER_GUESS -ne $SECRET_NUMBER ]]; do
    if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
    else
      if [[ $USER_GUESS -lt $SECRET_NUMBER ]]; then
        echo "It's higher than that, guess again:"
      elif [[ $USER_GUESS -gt $SECRET_NUMBER ]]; then
        echo "It's lower than that, guess again:"
      fi
    fi
    read USER_GUESS
    ((GUESS_COUNT++))
  done

  ((GUESS_COUNT++))

  INSERT_GAME_RESULT=$($PSQL "INSERT INTO games (user_id, secret_number, number_of_guesses) VALUES ($USER_ID, $SECRET_NUMBER, $GUESS_COUNT)")

  echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
}

get_user_info
start_game
#!/bin/bash

# Set up the database query command
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if the user exists in the database
USER_INFO=$($PSQL "SELECT user_id, games_played, COALESCE(best_game, 0) FROM scores WHERE username='$USERNAME';")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO scores (username) VALUES ('$USERNAME') RETURNING user_id;")
  USER_ID=$(echo $INSERT_USER | xargs)
  GAMES_PLAYED=0
  BEST_GAME=0
else
  # Returning user
  IFS='|' read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate a random number between 1 and 1000
SECRET_NUMBER=$((RANDOM % 1000 + 1))
GUESS_COUNT=0
echo "Guess the secret number between 1 and 1000:"

while true; do
  read USER_GUESS
  ((GUESS_COUNT++))

  # Check for valid integer input
  if ! [[ $USER_GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Compare guess to the secret number
  if [[ $USER_GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $USER_GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Update database with game stats
INSERT_GAME=$($PSQL "INSERT INTO games (user_id, secret_number, number_of_guesses) VALUES ($USER_ID, $SECRET_NUMBER, $GUESS_COUNT);")
UPDATE_STATS=$($PSQL "UPDATE scores SET games_played = games_played + 1, best_game = LEAST(best_game, $GUESS_COUNT) WHERE user_id = $USER_ID;")

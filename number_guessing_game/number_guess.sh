#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

# Check if the user exists
USER_CHECK=$($PSQL "SELECT username FROM user_info WHERE username='$USERNAME'")

if [[ -z $USER_CHECK ]]; then
  # New user
  echo -e "Welcome, $USERNAME! It looks like this is your first time here."
  ADD_USER=$($PSQL "INSERT INTO user_info(username) VALUES('$USERNAME')")
else
  # Returning user
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM user_info WHERE username='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM user_info WHERE username='$USERNAME'")
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the game
echo -e "Guess the secret number between 1 and 1000:"
G_NUMBER=$(($RANDOM % 1000 + 1))
let COUNT=0

read USER_INPUT

until [ $USER_INPUT -eq $G_NUMBER ]; do
  let COUNT++

  if ! [[ $USER_INPUT =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  elif [ $USER_INPUT -gt $G_NUMBER ]; then
    echo "It’s lower than that, guess again:"
  elif [ $USER_INPUT -lt $G_NUMBER ]; then
    echo "It’s higher than that, guess again:"
  fi

  read USER_INPUT
done

let COUNT++

# Final message
echo "You guessed it in $COUNT tries. The secret number was $G_NUMBER. Nice job!"

# Update stats in the database
INCREMENT_GAMES_PLAYED=$($PSQL "UPDATE user_info SET games_played = games_played + 1 WHERE username='$USERNAME'")
UPDATE_BEST_GAME=$($PSQL "UPDATE user_info SET best_game = $COUNT WHERE username='$USERNAME' AND (best_game > $COUNT OR best_game IS NULL)")

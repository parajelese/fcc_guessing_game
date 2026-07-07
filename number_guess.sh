#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
  

USER_NAME_INPUT(){
echo "Enter your username:"
read USER_NAME
if [[ ! ${#USER_NAME} -le 22 && ${#USER_NAME} -gt 0 ]]
then
echo "User name must have from 1 to 22 characters!"
USER_NAME_INPUT
else
#validate if exist in database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE user_name = '$USER_NAME' LIMIT 1")
if [[ ! -z $USER_ID ]]
then
GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id = $USER_ID LIMIT 1")
BEST_GAME=$($PSQL "SELECT best_game FROM game WHERE user_id = $USER_ID LIMIT 1")
echo "Welcome back, $USER_NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
NUMBER_TO_GUESS=$(((RANDOM % 1000) + 1 ))
GUESS_NUMBER
else
echo "Welcome, $USER_NAME! It looks like this is your first time here." 
NUMBER_TO_GUESS=$(((RANDOM % 1000) + 1 ))
GUESS_NUMBER
fi
fi
}
GUESS_NUMBER(){
echo -e "\nGuess the secret number between 1 and 1000:"
read GUESS_NUMBER_INPUT  
if [[ ! -z $GUESS_NUMBER_INPUT ]]
then 
 ((ATTEMPTS++))
if [[ ! $GUESS_NUMBER_INPUT =~ ^[0-9]+$ ]]
then   
 echo "That is not an integer, guess again:"
else
 if [[ $GUESS_NUMBER_INPUT -lt $NUMBER_TO_GUESS ]]
 then
 echo "It's lower than that, guess again:"
 GUESS_NUMBER
 elif [[ $GUESS_NUMBER_INPUT -gt $NUMBER_TO_GUESS ]]
 then
 echo "It's higher than that, guess again:"
 GUESS_NUMBER
 elif [[ $GUESS_NUMBER_INPUT -eq $NUMBER_TO_GUESS ]]
 then
 echo "You guessed it in $ATTEMPTS tries. The secret number was $NUMBER_TO_GUESS. Nice job!"
 ADD_UPDATE_USER     
 fi   
 fi
else 
GUESS_NUMBER
fi
}
ADD_UPDATE_USER(){
  DB_USER=$($PSQL "SELECT user_name,games_played FROM users WHERE user_name = '$USER_NAME' LIMIT 1")
  if [[ -z $DB_USER ]]
  then
   INSERT_USER_RESULT=$($PSQL "INSERT INTO users(user_name,games_played) VALUES('$USER_NAME',1)")
   if [[ $INSERT_USER_RESULT == "INSERT 0 1" ]]
   then
   NEW_USER_ID=$($PSQL "SELECT user_id FROM users WHERE user_name='$USER_NAME' LIMIT 1")
   INSERT_GAME_RESULT=$($PSQL "INSERT INTO game(user_id,best_game) VALUES($NEW_USER_ID,$ATTEMPTS)")
   fi  
  else
  #get fewer attempts
 UPDATE_USER_GAMES_RESULT=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED + 1 WHERE user_name = '$USER_NAME'")
   if [[ $ATTEMPTS -lt $BEST_GAME ]]
   then   
   UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE game SET best_game = $ATTEMPTS WHERE user_id = $USER_ID")   
   fi
  fi
}
USER_NAME_INPUT
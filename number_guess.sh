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
DB_USER_NAME=$($PSQL "SELECT user_name,games_played,best_game FROM users INNER JOIN game using(user_id) WHERE user_name = '$USER_NAME' LIMIT 1")
if [[ ! -z $DB_USER_NAME ]]
then
#If that username has been used before
echo $DB_USER_NAME | while IFS="|" read UN GP BG
do
echo  "Welcome back, $UN! You have played $GP games, and your best game took $BG guesses." 
done   
GUESS_NUMBER
else
echo -e "\nWelcome, $USER_NAME! It looks like this is your first time here." 
GUESS_NUMBER
fi
NUMBER_TO_GUESS=$(((RANDOM % 1000) + 1 )) 
fi
}
GUESS_NUMBER(){   
echo -e "\nGuess the secret number between 1 and 1000:\n"
read GUESS_NUMBER_INPUT  
if [[ ! -z $GUESS_NUMBER_INPUT ]]
then 
if [[ ! $GUESS_NUMBER_INPUT =~ ^[0-9]+$ ]]
then   
 echo "That is not an integer, guess again:"
else
 if [[ $GUESS_NUMBER_INPUT -lt $NUMBER_TO_GUESS ]]
 then
 ((ATTEMPTS++))
 echo -e "\nAttempts: $ATTEMPTS"
 echo "It's lower than that, guess again:"
 GUESS_NUMBER
 elif [[ $GUESS_NUMBER_INPUT -gt $NUMBER_TO_GUESS ]]
 then
 ((ATTEMPTS++))
 echo -e "\nAttempts: $ATTEMPTS"
 echo "It's higher than that, guess again:"
 GUESS_NUMBER
 elif [[ $GUESS_NUMBER_INPUT -eq $NUMBER_TO_GUESS ]]
 then
 ((ATTEMPTS++))
 echo -e "\nAttempts: $ATTEMPTS"
 echo "You guessed it in $ATTEMPTS tries. The secret number was $NUMBER_TO_GUESS. Nice job!"
 ADD_UPDATE_USER     
 fi   
 fi
else 
GUESS_NUMBER
fi
}
ADD_UPDATE_USER(){
  DB_USER=$($PSQL "SELECT user_name,games_played FROM users WHERE user_name = '$USER_NAME'")
  if [[ -z $DB_USER ]]
  then
   INSERT_GAME_USER_RESULT=$($PSQL "INSERT INTO users(user_name,games_played) VALUES('$USER_NAME',1)")
   if [[ $INSERT_GAME_USER_RESULT == "INSERT 0 1" ]]
   then
    NEW_USER_ID=$($PSQL "SELECT user_id FROM users WHERE user_name='$USER_NAME' LIMIT 1")
   INSERT_GAME_RESULT=$($PSQL "INSERT INTO game(user_id,best_game) VALUES($NEW_USER_ID,$ATTEMPTS)")
   fi  
  else
  #get fewer attempts
  GET_BEST_GAME=$($PSQL "SELECT user_name,games_played,best_game FROM users INNER JOIN game USING(user_id) WHERE user_name = '$USER_NAME' LIMIT 1")
  echo $GET_BEST_GAME | while IFS="|" read UNAME GAMEP BEST_GAME
  do
   if [[ $ATTEMPTS -lt $BEST_GAME ]]
   then  
   UPDATE_USER_GAMES_RESULT=$($PSQL "UPDATE users SET games_played = $GAMEP + 1 WHERE user_name = '$UNAME'")
   UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE game SET best_game = $ATTEMPTS WHERE user_name = '$UNAME'")
   else  
   UPDATE_USER_GAMES_RESULT=$($PSQL "UPDATE users SET games_played = $GAMEP + 1 WHERE user_name = '$UNAME'")
   fi
  done 
  fi
}
USER_NAME_INPUT
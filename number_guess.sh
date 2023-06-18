#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(($RANDOM % 1001))
GUESS="NULL"

CREATE_USER() {
    if [[ $1 ]]
    then
        INSERT_USER_RESULT=$($PSQL "INSERT INTO users (name) VALUES ('$1');")
    fi
}

ASK_NAME() {
    echo -n "Enter your username: "
    read USERNAME

    USERNAME_LENGTH=$(echo -n $USERNAME | wc -m)

    if [ $USERNAME_LENGTH -lt 2 ] || [ $USERNAME_LENGTH -gt 25 ]
    then
        echo "Invalid username, minimum 2 and maximum 25 characters."
        ASK_NAME
    fi
}

ASK_GUESS() {
    echo -e -n "$1"
    read GUESS
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
        ASK_GUESS "That is not an integer, guess again: "
    fi
}

COUNT_TRIES() {
    if [[ -z NUMBER_OF_TRIES ]]
    then
        NUMBER_OF_TRIES=1
    else
        NUMBER_OF_TRIES=$(($NUMBER_OF_TRIES + 1))
    fi
}

SAVE_GAME() {
    if [ $1 ] && [ $2 ]
    then
        INSERT_GAME_RESULT=$($PSQL "INSERT INTO games (user_id, number_of_guesses) VALUES ($1, $2);")
    fi
}

GET_TOTAL_MATCHES() {
    if [[ $1 ]]
    then
        TOTAL_MATCHES=$($PSQL "SELECT count(*) FROM games WHERE user_id = '$1';")
    fi
}

GET_MIN_NUMBER_OF_GUESSES() {
    if [[ $1 ]]
    then
        MIN_NUMBER_OF_GUESSES=$($PSQL "SELECT number_of_guesses FROM games WHERE user_id = '$1' ORDER BY number_of_guesses LIMIT 1;")
    fi
}

ASK_NAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME';")

if [[ -z $USER_ID ]]
then
    CREATE_USER $USERNAME
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME';")

    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
    GET_TOTAL_MATCHES $USER_ID
    GET_MIN_NUMBER_OF_GUESSES $USER_ID

    echo -e "\nWelcome back, $USERNAME! You have played $TOTAL_MATCHES games, and your best game took $MIN_NUMBER_OF_GUESSES guesses."
fi

MSG="\nGuess the secret number between 1 and 1000: "

until [ $GUESS -eq $SECRET_NUMBER ]
do
    ASK_GUESS "$MSG"
    COUNT_TRIES

    if [[ $GUESS -gt $SECRET_NUMBER ]]
    then
        MSG="It's lower than that, guess again: "
    fi
    if [[ $GUESS -lt $SECRET_NUMBER ]]
    then
        MSG="It's higher than that, guess again: "
    fi
done

SAVE_GAME $USER_ID $NUMBER_OF_TRIES

echo -e "\nYou guessed it in $NUMBER_OF_TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"

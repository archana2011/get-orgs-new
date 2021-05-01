#!/bin/bash

rm nextorglinks > /dev/null 2>&1
export token=$OCTOKIT_ACCESS_TOKEN
export pagelen=100
export apiendpoint=$OCTOKIT_API_ENDPOINT

if [[ $(echo "${apiendpoint: -1}") = / ]]
then
        apiendpoint=$(echo ${apiendpoint::-1})
fi

linkheader="true"

curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" -X GET "${apiendpoint}/organizations?per_page=5" | jq .[].login | tr -d '"'

link=$(curl -i -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" -X GET "${apiendpoint}/organizations?per_page=${pagelen}" | awk -F " " '/Link:/ {print $2}' | tr -d "<>;")

echo $link >> nextorglinks

while [[ $linkheader=true ]]
do
        link=$(curl -i -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" -X GET "$link" | awk -F " " '/Link:/ {print $2}' | tr -d "<>;")
        echo $link >> nextorglinks
        if [[ $link=${apiendpoint}/organizations{?since} ]]
        then
                break
        fi
done

while read line || [ -n "$line" ]
do
        curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" -X GET "$line" | jq .[].login | tr -d '"'
done < "nextorglinks"

rm nextorglinks > /dev/null 2>&1

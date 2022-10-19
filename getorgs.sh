#!/usr/bin/bash

rm nextorglinks > /dev/null 2>&1
rm orgnames > /dev/null 2>&1

export token=GITHUB_TOKEN
export pagelen=100
export apiendpoint=HTTPS_SERVER_URL

if [[ $(echo "${apiendpoint: -1}") = / ]]
then
        apiendpoint=$(echo ${apiendpoint::-1})
fi

curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" -X GET "${apiendpoint}/organizations?per_page=${pagelen}" | jq .[].login | tr -d '"' >> orgnames.csv
link=$(curl -i -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" -X GET "${apiendpoint}/organizations?per_page=${pagelen}" | awk -F " " '/link:/ {print $2}' | tr -d "<>;")
echo $link >> nextorglinks

if [[ $link = ${apiendpoint}/organizations{?since} ]]
then
        break
fi

while [[ $link != ${apiendpoint}/organizations{?since} ]]
do
        if [[ $link != ${apiendpoint}/organizations{?since} ]]
        then
        link=$(curl -i -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" -X GET "$link""&per_page=100" | awk -F " " '/link:/ {print $2}' | tr -d "<>;")
        echo $link >> nextorglinks
        fi
done

sed -i '$d' nextorglinks
while read line || [ -n "$line" ]
do
        curl -s -H "Accept: application/vnd.github.v3+json" -H "Authorization: token $token" -X GET "$line" | jq .[].login | tr -d '"' >> orgnames.csv
done < "nextorglinks"

rm nextorglinks > /dev/null 2>&1
sed -i 's/\r//g' orgnames.csv

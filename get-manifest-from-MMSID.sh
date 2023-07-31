#!/bin/bash
input_file=$1
output_file=$2

rm -f $output_file

while IFS="," read -r column1 column2 column3 column4
 do
  manifest=$(curl 'https://figgy.princeton.edu/graphql' \
    -H 'content-type: application/json' \
    --data-raw $'{"operationName":"GetResourcesByOrangelightId","variables":{"id":'\"$column1\"'},"query":"query GetResourcesByOrangelightId($id: String\u0021) {\n  resourcesByOrangelightId(id: $id) {\n    id\n    label\n    url\n    embed {\n      type\n      content\n      status\n      __typename\n    }\n    notice {\n      heading\n      acceptLabel\n      textHtml\n      __typename\n    }\n    ... on ScannedResource {\n      manifestUrl\n      __typename\n    }\n    ... on ScannedMap {\n      manifestUrl\n      __typename\n    }\n    ... on Coin {\n      manifestUrl\n      __typename\n    }\n    __typename\n  }\n}"}' | jq .data.resourcesByOrangelightId | jq -r '.[] | .manifestUrl')
  echo "$column1,$column2, $column3, $column4, $manifest" >> $output_file
done < <(cut -d ',' -f1,2,3,4 $input_file | tail -n +2) # | head -n 5


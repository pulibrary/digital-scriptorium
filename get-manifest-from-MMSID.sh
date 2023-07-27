

curl 'https://figgy.princeton.edu/graphql'   -H 'content-type: application/json'   --data-raw $'{
"operationName":"GetResourcesByOrangelightId",
"variables":{"id":"9923628163506421"},
"query":"query GetResourcesByOrangelightId($id: String\u0021) 
{\\n  resourcesByOrangelightId(id: $id) 
{\\n    id\\n    label\\n    url\\n    
embed {\\n      type\\n      content\\n      status\\n      __typename\\n    }\\n    
notice {\\n      heading\\n      acceptLabel\\n      textHtml\\n      __typename\\n    }\\n    
... on ScannedResource {\\n      manifestUrl\\n      __typename\\n    }\\n    
... on ScannedMap {\\n      manifestUrl\\n      __typename\\n    }\\n    
... on Coin {\\n      manifestUrl\\n      __typename\\n    }\\n    __typename\\n  }\\n}"
}'

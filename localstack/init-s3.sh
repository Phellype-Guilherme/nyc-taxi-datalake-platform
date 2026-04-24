#!/bin/bash
awslocal s3 mb s3://nyc-taxi-datalake || true

awslocal s3api put-bucket-cors --bucket nyc-taxi-datalake --cors-configuration '{
  "CORSRules":[{"AllowedOrigins":["*"],"AllowedMethods":["GET","HEAD"],"AllowedHeaders":["*"],"ExposeHeaders":["ETag","Last-Modified"]}]
}'

awslocal s3api put-bucket-policy --bucket nyc-taxi-datalake --policy '{
  "Version":"2012-10-17",
  "Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::nyc-taxi-datalake/exports/*"}]
}'

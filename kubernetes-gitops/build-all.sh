#!/bin/bash

cd src
cd adservice
sudo docker build -t isieiam/hipster-adservice:0.0.1 .
sudo docker push isieiam/hipster-adservice:0.0.1
cd ..
cd checkoutservice
sudo docker build -t isieiam/hipster-checkoutservice:0.0.1 .
sudo docker push isieiam/hipster-checkoutservice:0.0.1
cd ..
cd emailservice
sudo docker build -t isieiam/hipster-emailservice:0.0.1 .
sudo docker push isieiam/hipster-emailservice:0.0.1
cd ..
cd loadgenerator
sudo docker build -t isieiam/hipster-loadgenerator:0.0.1 .
sudo docker push isieiam/hipster-loadgenerator:0.0.1
cd ..
cd productcatalogservice
sudo docker build -t isieiam/hipster-productcatalogservice:0.0.1 .
sudo docker push isieiam/hipster-productcatalogservice:0.0.1
cd ..
cd shippingservice
sudo docker build -t isieiam/hipster-shippingservice:0.0.1 .
sudo docker push isieiam/hipster-shippingservice:0.0.1
cd ..
cd cartservice
sudo docker build -t isieiam/hipster-cartservice:0.0.1 .
sudo docker push isieiam/hipster-cartservice:0.0.1
cd ..
cd currencyservice
sudo docker build -t isieiam/hipster-currencyservice:0.0.1 .
sudo docker push isieiam/hipster-currencyservice:0.0.1
cd ..
cd frontend
sudo docker build -t isieiam/hipster-frontend:0.0.1 .
sudo docker push isieiam/hipster-frontend:0.0.1
cd ..
cd paymentservice
sudo docker build -t isieiam/hipster-paymentservice:0.0.1 .
sudo docker push isieiam/hipster-paymentservice:0.0.1
cd ..
cd recommendationservice
sudo docker build -t isieiam/hipster-recommendationservice:0.0.1 .
sudo docker push isieiam/hipster-recommendationservice:0.0.1

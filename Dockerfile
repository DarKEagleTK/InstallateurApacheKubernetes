FROM debian:latest
RUN apt update && apt upgrade -y 
RUN apt install apache2 -y
RUN mkdir /etc/certificats

EXPOSE 80
EXPOSE 443
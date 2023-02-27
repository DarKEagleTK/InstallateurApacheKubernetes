FROM debian:latest
RUN apt update
RUN apt install apache2
RUN mkdir /etc/certificats
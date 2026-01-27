FROM node:25 AS builder

WORKDIR /app 

COPY . .

FROM httpd:alpine

WORKDIR /usr/local/apache2/htdocs/ 

COPY --from=builder /app .

EXPOSE 80

CMD ["httpd", "-D", "FOREGROUND"]
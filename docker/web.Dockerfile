FROM nginx:1.31.3-alpine

COPY ./docker/web/nginx.conf /etc/nginx/nginx.conf
COPY ./www-root /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]
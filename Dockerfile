FROM nginx:alpine
COPY app-terra/ /usr/share/nginx/html/
EXPOSE 80

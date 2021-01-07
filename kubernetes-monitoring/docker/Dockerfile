FROM nginx:1.19.5-alpine

WORKDIR /app
RUN adduser -D -u 1001 -g 'nginx' nginx2 \
 && chown -R nginx2:nginx /var/run \
 && chown -R nginx2:nginx /app/ \
 && chown -R nginx2:nginx /var/cache/nginx \
 && touch /var/run/nginx.pid \
 && chown -R nginx2:nginx /var/run/nginx.pid

COPY default.conf /etc/nginx/conf.d/default.conf
COPY homework.html /app/homework.html

EXPOSE 8000
USER 1001

CMD ["nginx", "-g", "daemon off;"]

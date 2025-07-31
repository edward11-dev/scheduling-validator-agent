FROM postgres:13
ENV POSTGRES_DB=customer_data
ENV POSTGRES_USER=user
ENV POSTGRES_PASSWORD=password
COPY init.sql /docker-entrypoint-initdb.d/

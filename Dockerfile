# === Stage 1: Build Stage ===
# Use the official Maven image. It already has JDK 11 and Maven installed.
FROM maven:3.8.6-openjdk-11-slim AS build
WORKDIR /app

# Copy only the pom.xml files first to leverage Docker caching for dependencies
COPY pom.xml .
COPY webapp/pom.xml webapp/
RUN mvn dependency:go-offline -B

# Copy the source code and build the WAR file
COPY . .
RUN mvn clean package -DskipTests

# === Stage 2: Runtime Stage ===
# Use the official Tomcat 9 image. It is pre-configured and ready to run.
FROM tomcat:9.0-jdk11-openjdk-slim
WORKDIR /usr/local/tomcat

# Optional: Remove default webapps to keep it clean, then copy your WAR
RUN rm -rf webapps/*
COPY --from=build /app/webapp/target/webapp.war webapps/webapp.war

# ✅ Setup Tomcat users for GUI access (if you still need the manager)
RUN echo '<tomcat-users>' > conf/tomcat-users.xml && \
    echo '  <role rolename="manager-gui"/>' >> conf/tomcat-users.xml && \
    echo '  <role rolename="admin-gui"/>' >> conf/tomcat-users.xml && \
    echo '  <user username="admin" password="admin" roles="manager-gui,admin-gui"/>' >> conf/tomcat-users.xml && \
    echo '</tomcat-users>' >> conf/tomcat-users.xml

EXPOSE 8080

# The official Tomcat image already has the CMD ["catalina.sh", "run"]

# === Stage 1: Build Stage ===
FROM maven:3.8.6-openjdk-11-slim AS build
WORKDIR /app

# Copy the entire project first to avoid "missing module" errors
COPY . .

# Build the webapp specifically
# We use -pl (project list) to focus on the webapp and -am (also make) for dependencies
RUN mvn clean package -pl webapp -am -DskipTests

# === Stage 2: Runtime Stage ===
FROM tomcat:9.0-jdk11-openjdk-slim
WORKDIR /usr/local/tomcat

# 1. Move default apps (including Manager) to a temp folder, 
#    clean webapps, then move them back.
RUN mv webapps.dist/* webapps/

# 2. Setup Tomcat users for GUI access
RUN echo '<tomcat-users>' > conf/tomcat-users.xml && \
    echo '  <role rolename="manager-gui"/>' >> conf/tomcat-users.xml && \
    echo '  <role rolename="admin-gui"/>' >> conf/tomcat-users.xml && \
    echo '  <user username="admin" password="admin" roles="manager-gui,admin-gui"/>' >> conf/tomcat-users.xml && \
    echo '</tomcat-users>' >> conf/tomcat-users.xml

# 3. Allow remote access to the Manager (Remove IP address valve)
RUN sed -i 's|<Valve||g' webapps/manager/META-INF/context.xml

# 4. Deploy your WAR file
COPY --from=build /app/webapp/target/*.war webapps/webapp.war

EXPOSE 8080

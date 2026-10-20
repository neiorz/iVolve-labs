# Part 1: Build inside Docker
# Maven image with Java 17, alpine variant to keep the image small
FROM maven:3-eclipse-temurin-17-alpine

# working directory
WORKDIR /app

# non-root user (BusyBox adduser on alpine)
RUN adduser -D -u 1000 appuser

# copy the source code and build the application
COPY pom.xml .
COPY src ./src
RUN mvn -B clean package

# run the generated JAR, expose port 8080
EXPOSE 8080
USER appuser
CMD ["java", "-jar", "target/calculator.jar"]

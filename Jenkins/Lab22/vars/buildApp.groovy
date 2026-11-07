def call() {
    echo "Running unit tests..."
    sh "mvn test"
    echo "Building the application..."
    sh "mvn clean package -DskipTests"
}

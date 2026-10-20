# Lab 1: Building and Packaging a Java Application with Maven

- **Source code:** https://github.com/Ibrahim-Adel15/CalculatorMavenApp.git (copy included in this folder: `CalculatorMavenApp/`)

## Objective

Learn how to use **Apache Maven** to test, build, and package a Java application into an executable JAR file (`target/calculator.jar`), then run and verify it.

## Lab Tasks

1. Install Java and Maven.
2. Clone the source code.
3. Run the unit tests.
4. Build the app (generate artifact in `target/calculator.jar`).
5. Run the app.
6. Verify the app is working.

---

## Step 1: Install Java and Maven

Verify the installed versions:

```bash
java -version
mvn -version
```

Output on this machine:

```text
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
Apache Maven 3.8.7
```

If they are not installed (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk maven
```

> The app targets Java 17 (`maven.compiler.source/target = 17`), so Java 17+ is required. Java 21 also works.

## Step 2: Clone the Source Code

```bash
git clone https://github.com/Ibrahim-Adel15/CalculatorMavenApp.git
cd CalculatorMavenApp
```

Project structure:

```text
CalculatorMavenApp/
├── pom.xml
└── src/
    ├── main/java/com/example/calculator/
    │   ├── Calculator.java      # sum / subtract / multiply / divide
    │   └── Main.java            # interactive CLI entry point
    └── test/java/com/example/calculator/
        └── CalculatorTest.java  # 5 JUnit 5 tests
```

Key points from `pom.xml`:
- `groupId` `com.example`, `artifactId` `calculator`, `version` `1.0.0`, packaging `jar`.
- `<finalName>calculator</finalName>` → artifact is named `calculator.jar`.
- `maven-surefire-plugin:3.2.5` runs the JUnit 5 tests in the `test` phase.
- `maven-jar-plugin:3.4.1` sets `Main-Class: com.example.calculator.Main` so the jar is runnable with `java -jar`.

## Step 3: Run Unit Tests

```bash
mvn test
```

Result — **all 5 tests passed**:

```text
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running com.example.calculator.CalculatorTest
Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.119 s -- in com.example.calculator.CalculatorTest

Results:
Tests run: 5, Failures: 0, Errors: 0, Skipped: 0

BUILD SUCCESS
```

Tests cover: `testSum`, `testSubtract`, `testMultiply`, `testDivide`, `testDivideByZeroThrowsException`.

## Step 4: Build the App (Generate the Artifact)

```bash
mvn clean package
```

Verify the artifact was created:

```bash
ls -lh target/calculator.jar
```

```text
-rw-rw-r-- 1 nourz nourz 3.7K Oct 20 17:33 target/calculator.jar
```

The `package` lifecycle also re-runs the tests (test failures would stop the build), then `maven-jar-plugin` produces the executable jar with this manifest:

```text
Manifest-Version: 1.0
Created-By: Maven JAR Plugin 3.4.1
Main-Class: com.example.calculator.Main
```

## Step 5: Run the App

The app is an interactive CLI that asks for two numbers:

```bash
java -jar target/calculator.jar
```

It can also be fed input non-interactively:

```bash
printf '10\n5\n' | java -jar target/calculator.jar
```

## Step 6: Verify the App Is Working

```text
Enter first number: Enter second number: a = 10.0, b = 5.0
Sum: 15.0
Subtract: 5.0
Multiply: 50.0
Divide: 2.0
```

Second test with decimals (`3.5` and `2.5`):

```text
a = 3.5, b = 2.5
Sum: 6.0
Subtract: 1.0
Multiply: 8.75
Divide: 1.4
```

All results are mathematically correct → **app verified working**.

---

## Summary

| Task | Command | Result |
|------|---------|--------|
| Install Java & Maven | `java -version` / `mvn -version` | OpenJDK 21, Maven 3.8.7 |
| Clone source | `git clone ...CalculatorMavenApp.git` | Cloned ✅ |
| Run unit tests | `mvn test` | 5/5 tests passed ✅ |
| Build app | `mvn clean package` | `target/calculator.jar` generated ✅ |
| Run app | `java -jar target/calculator.jar` | Runs ✅ |
| Verify app | enter `10` and `5` | Sum 15.0, Sub 5.0, Mul 50.0, Div 2.0 ✅ |

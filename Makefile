all: build

build:
	mkdir -p bin
	java -cp ".:antlr-3.4.jar" org.antlr.Tool src/COOLTreeBuilder.g -fo ./src
	java -cp ".:antlr-3.4.jar" org.antlr.Tool src/COOLTreeChecker.g -fo ./src
	javac -cp ".:java-cup-11a-runtime.jar:antlr-3.4.jar" -d "./bin" ./src/*.java
clean:
	rm ./bin/*.class

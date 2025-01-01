# Makefile for building Analisador using flex and gcc

# Variables
FLEX = flex
CC = gcc
FLEX_INPUT = Analisador.l
FLEX_OUTPUT = Analisador.c
TARGET = Analisador
CFLAGS = -lm -ll

# Default target
all: $(TARGET)

# Rule to build the executable
$(TARGET): $(FLEX_OUTPUT)
	$(CC) $(FLEX_OUTPUT) -o $(TARGET) $(CFLAGS)

# Rule to generate the C file from the lex file
$(FLEX_OUTPUT): $(FLEX_INPUT)
	$(FLEX) -o $(FLEX_OUTPUT) $(FLEX_INPUT)

# Debugging target
debug: $(FLEX_INPUT)
	$(FLEX) -d -o $(FLEX_OUTPUT) $(FLEX_INPUT)
	$(CC) $(FLEX_OUTPUT) -o $(TARGET) $(CFLAGS)
	@echo "Debugging build complete. Run ./$(TARGET) to test with verbose output."


# Clean up generated files
clean:
	rm -f $(FLEX_OUTPUT) $(TARGET)

# Phony targets
.PHONY: all clean
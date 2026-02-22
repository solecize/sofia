# Sofia CLI - Makefile
# Builds the sofia command-line tool

CC = cc
CFLAGS = -Wall -Wextra -O2 -std=c99 -Ivendor/tomlc99
LDFLAGS =

SRC_DIR = src
VENDOR_DIR = vendor/tomlc99
BUILD_DIR = build
BIN_DIR = bin

SOURCES = $(SRC_DIR)/sofia.c $(VENDOR_DIR)/toml.c
TARGET = $(BIN_DIR)/sofia
EXTRACT_SRC = $(SRC_DIR)/extract.c
EXTRACT_BIN = $(BIN_DIR)/sofia-extract
COMPILE_SRC = $(SRC_DIR)/compile.c
COMPILE_BIN = $(BIN_DIR)/sofia-compile

.PHONY: all clean install debug test

all: $(TARGET) $(EXTRACT_BIN) $(COMPILE_BIN)

$(TARGET): $(SOURCES) | $(BIN_DIR)
	$(CC) $(CFLAGS) -I$(VENDOR_DIR) -o $@ $(SOURCES) $(LDFLAGS)

$(EXTRACT_BIN): $(EXTRACT_SRC) | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $(EXTRACT_SRC) $(LDFLAGS)

$(COMPILE_BIN): $(COMPILE_SRC) | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $(COMPILE_SRC) $(LDFLAGS)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean:
	rm -rf $(BIN_DIR)

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/sofia

# Development build with debug symbols
debug: CFLAGS = -Wall -Wextra -g -std=c99 -DDEBUG
debug: $(TARGET)

# Run tests
test: $(TARGET)
	@echo "Running smoke tests..."
	@$(TARGET) notator list
	@echo ""
	@$(TARGET) notator run -process -preview

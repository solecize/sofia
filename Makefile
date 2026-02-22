# Sofia CLI - Makefile
# Builds the sofia command-line tool

CC = cc
CFLAGS = -Wall -Wextra -O2 -std=c99
LDFLAGS =

SRC_DIR = src
VENDOR_DIR = vendor/tomlc99
BUILD_DIR = build
BIN_DIR = bin

SOURCES = $(SRC_DIR)/sofia.c $(VENDOR_DIR)/toml.c
TARGET = $(BIN_DIR)/sofia

.PHONY: all clean install

all: $(TARGET)

$(TARGET): $(SOURCES) | $(BIN_DIR)
	$(CC) $(CFLAGS) -I$(VENDOR_DIR) -o $@ $(SOURCES) $(LDFLAGS)

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

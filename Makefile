# SPDX-License-Identifier: MIT
# Copyright (c) 2026 TinkeringDao
# Unofficial macOS NVRAM & DSP Interoperability Utility for Bose QuietComfort Ultra Headphones
# Independent clean-room macOS IOBluetooth build configuration (See LEGAL.md).

CC = clang
CFLAGS = -fobjc-arc -Wall -Wextra -Wno-deprecated-declarations -O2
FRAMEWORKS = -framework Foundation -framework IOBluetooth
TARGET = bose-ultra-tuner
SRC = bose_ultra_tuner.m

.PHONY: all woke baseline status scan wizard clean

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(SRC) -o $(TARGET)

woke: $(TARGET)
	./$(TARGET) woke

baseline: $(TARGET)
	./$(TARGET) baseline

status: $(TARGET)
	./$(TARGET) status

scan: $(TARGET)
	./$(TARGET) scan

wizard: $(TARGET)
	./bose-ultra-wizard.sh

clean:
	rm -f $(TARGET)

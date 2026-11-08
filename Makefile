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

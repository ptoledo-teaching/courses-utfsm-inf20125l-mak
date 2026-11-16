CC = gcc
CPPFLAGS =
CFLAGS = -Wall -Wextra -std=c11 -g -O0
DEPFLAGS = -MMD -MP
TARGET = relay_example
OBJS = main.o checksum.o decoder.o
DEPS = $(OBJS:.o=.d)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(DEPFLAGS) -c -o $@ $<

clean:
	rm -f $(TARGET) $(OBJS) $(DEPS)

-include $(DEPS)

.PHONY: all clean

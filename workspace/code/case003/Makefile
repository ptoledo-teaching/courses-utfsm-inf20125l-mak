CC = # TODO: completar
CPPFLAGS =
CFLAGS = # TODO: completar
DEPFLAGS = # TODO: completar
TARGET = rebel_link
OBJS = # TODO: completar
DEPS = $(OBJS:.o=.d)

all: $(TARGET)

$(TARGET): $(OBJS)
	# TODO: completar la receta de enlace

# TODO: escribir aqui la regla patron completa de compilacion

test: $(TARGET)
	../../scripts/tests-run.sh ./$(TARGET) ../../tests

clean:
	# TODO: completar la receta de limpieza

-include $(DEPS)

.PHONY: all test clean

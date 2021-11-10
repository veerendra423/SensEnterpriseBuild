APP = copy_files
MUSL_CC = musl-gcc
SCONE_CC = SCONE_SHARED=yes scone-gcc
CMD = $< -o $(APP) ./libsensattest.so -O3 -Wall
SRC = copy_files.c

ifeq ($(DEBUG),yes)
CMD += -g
endif

all : with-gcc

with-gcc : $(SRC)
	$(CC) $(CMD)

with-musl : $(SRC)
	$(MUSL_CC) $(CMD)

with-scone : $(SRC)
	$(SCONE_CC) $(CMD)

clean:
	rm ${APP}

.PHONY: all clean 

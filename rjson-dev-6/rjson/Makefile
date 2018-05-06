TARGET =        rjson.so
PREFIX =        ${HOME}/.lua
CFLAGS =        -O3 -Wall -pedantic -DNDEBUG
RJSON_CFLAGS =  -fpic
RJSON_LDFLAGS = -shared
LUA_INCDIR =    $(PREFIX)/include
LUA_LIBDIR =    $(PREFIX)/lib

BUILD_CFLAGS =  -I$(LUA_INCDIR) $(RJSON_CFLAGS)
OBJS =          rjson.o

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $(RJSON_LDFLAGS) -o $@ $(OBJS)

clean:
	rm -f *.o $(TARGET)

install: $(TARGET)
	cp $(TARGET) $(LUA_LIBDIR)
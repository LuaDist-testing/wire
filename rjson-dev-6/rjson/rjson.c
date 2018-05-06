#include "lua.h"
#include "lauxlib.h"
#include <stdlib.h>
#include <math.h>

static const char *char2escape[256] = {
    "\\u0000", "\\u0001", "\\u0002", "\\u0003",
    "\\u0004", "\\u0005", "\\u0006", "\\u0007",
    "\\b", "\\t", "\\n", "\\u000b",
    "\\f", "\\r", "\\u000e", "\\u000f",
    "\\u0010", "\\u0011", "\\u0012", "\\u0013",
    "\\u0014", "\\u0015", "\\u0016", "\\u0017",
    "\\u0018", "\\u0019", "\\u001a", "\\u001b",
    "\\u001c", "\\u001d", "\\u001e", "\\u001f",
    NULL, NULL, "\\\"", NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, "\\/",
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, "\\\\", NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, "\\u007f",
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
};

/* ===== DECODING ===== */

#define ch (unsigned char)**(data)
#define shift (*data)++

static void decode_value(lua_State *l, const char **data);
static void decode_value_with_null(lua_State *l, const char **data);

static void decode_string(lua_State *l, const char **data)
{
    shift;
    unsigned char c;
    int i = 0;
    while ((c = (unsigned char)*(*data + i)) != '"') {
        if (c == '\\') i++;
        i++;
    }
    lua_pushlstring(l, *data, i);
    (*data) += i + 1;
}

#define digits(n) {\
    for (;;shift) {\
        c = ch;\
        if ('0' <= c && c <= '9') {\
            n = n * 10 + (c & 15);\
        } else {\
            break;\
        }\
    }\
}

#define scientific_notation {\
    shift;\
    int n = 0;\
    if (ch == '+') {\
        shift;\
        digits(n);\
        for (;n;n--) x *= 10;\
    } else {\
        shift;\
        digits(n);\
        for (;n;n--) x /= 10;\
    }\
}

static void decode_number(lua_State *l, const char **data)
{
    unsigned char c;
    int neg;
    double x = 0;
    
    if (**data == '-') {
        neg = 1;
        shift;
    } else {
        neg = 0;
    }

    for (;;shift) {
        c = ch;
        if ('0' <= c && c <= '9') {
            x = x * 10 + (c & 15);
        } else if (c == 'e') {
            scientific_notation;
            break;
        } else if (c == '.') {
            shift;
            long tens = 1;
            for (;;shift) {
                c = ch;
                if ('0' <= c && c <= '9') {
                    tens *= 10;
                    x += (double) (c & 15) / tens;
                } else if (c == 'e') {
                    scientific_notation;
                    break;
                } else {
                    break;
                }
            }
            break;
        } else {
            break;
        }
    }

    lua_pushnumber(l, neg ? -x : x);
}

#define decode_pair(l, data) {\
    decode_string(l, data);\
    shift;\
    decode_value(l, data);\
    lua_rawset(l, -3);\
}

static void decode_object(lua_State *l, const char **data)
{
    shift;
    lua_newtable(l);
    unsigned char c = ch;
    if (c == '"') {
        decode_pair(l, data);
        while (**data == ',') {
            shift;
            decode_pair(l, data);
        }
    }
    shift;
}

static void decode_array(lua_State *l, const char **data)
{
    shift;
    lua_newtable(l);
    unsigned char c = ch;
    int i = 0;
    if (c != ']') {
        decode_value_with_null(l, data);
        lua_rawseti(l, -2, ++i);
        while (**data == ',') {
            do shift; while (**data == ' ');
            decode_value_with_null(l, data);
            lua_rawseti(l, -2, ++i);
        }
    }
    shift;
}

static void decode_value(lua_State *l, const char **data)
{
    unsigned char c = ch;

    if (c == '"') {
        decode_string(l, data);
    } else if (c == '-' || ('0' <= c && c <= '9')) {
        decode_number(l, data);
    } else if (c == 't') {
        (*data) += 4;
        lua_pushboolean(l, 1);
    } else if (c == 'f') {
        (*data) += 5;
        lua_pushboolean(l, 0);
    } else if (c == 'n') {
        (*data) += 4;
        lua_pushnil(l);
    } else if (c == '{') {
        decode_object(l, data);
    } else if (c == '[') {
        decode_array(l, data);
    }
}

static void decode_value_with_null(lua_State *l, const char **data)
{
    unsigned char c = ch;

    if (c == '"') {
        decode_string(l, data);
    } else if (c == '-' || ('0' <= c && c <= '9')) {
        decode_number(l, data);
    } else if (c == 't') {
        (*data) += 4;
        lua_pushboolean(l, 1);
    } else if (c == 'f') {
        (*data) += 5;
        lua_pushboolean(l, 0);
    } else if (c == 'n') {
        (*data) += 4;
        lua_pushlightuserdata(l, NULL);
    } else if (c == '{') {
        decode_object(l, data);
    } else if (c == '[') {
        decode_array(l, data);
    }
}

static int decode(lua_State *l)
{
    const char *data;
    size_t json_len;

    data = luaL_checklstring(l, 1, &json_len);

    decode_value(l, &data);

    return 1;
}

/* ===== ENCODING ===== */

typedef struct {
    size_t size;
    char *str;
    int i;
} buf_t;

static void encode_value(lua_State *l, buf_t *buf);

#define put(c) {\
    if (buf->size == buf->i) {\
        buf->size *= 2;\
        buf->str = (char *) realloc(buf->str, buf->size + 1);\
    }\
    buf->str[buf->i++] = c;\
}

#define put4(a, b, c, d) {\
    if ((buf->size - buf->i) < 4) {\
        buf->size *= 2;\
        buf->str = (char *) realloc(buf->str, buf->size + 1);\
    }\
    buf->str[buf->i] = a; buf->str[buf->i + 1] = b; buf->str[buf->i + 2] = c; buf->str[buf->i + 3] = d;\
    buf->i += 4;\
}

#define request_space(len) {\
    if ((buf->size - buf->i) < len) {\
        while ((buf->size - buf->i) < len) buf->size *= 2;\
        buf->str = (char *) realloc(buf->str, buf->size + 1);\
    }\
}

#define puts(buf, str, len) {\
    const char *escstr;\
    unsigned char c;\
    for (int i = 0; i < len; i++) {\
        c = str[i];\
        escstr = char2escape[c];\
        if (escstr) {\
            while (*escstr) buf->str[buf->i++] = *escstr++;\
        } else {\
            buf->str[buf->i++] = c;\
        }\
    }\
}

static void encode_str(lua_State *l, buf_t *buf, size_t len, const char *str) {
    request_space(len * 6 + 2);
    buf->str[buf->i++] = '\"';
    puts(buf, str, len);
    buf->str[buf->i++] = '\"';
}

static void encode_string(lua_State *l, buf_t *buf) {
    size_t len;
    const char *str;
    str = lua_tolstring(l, -1, &len);
    encode_str(l, buf, len, str);
}

static void encode_number(lua_State *l, buf_t *buf) {
    size_t len;
    const char *str = lua_tolstring(l, -1, &len);
    if ((unsigned char)*(str) > '9') {
        put4('n', 'u', 'l', 'l');
    } else {
        if ((buf->size - buf->i) < len) {
            buf->size *= 2;
            buf->str = (char *) realloc(buf->str, buf->size + 1);
        }
        for (int i = 0; i < len; i++) buf->str[buf->i++] = str[i];
    }
}

static void encode_boolean(lua_State *l, buf_t *buf) {
    if (lua_toboolean(l, -1)) {
        put4('t', 'r', 'u', 'e');
    } else {
        if ((buf->size - buf->i) < 5) {
            buf->size *= 2;
            buf->str = (char *) realloc(buf->str, buf->size + 1);
        }
        buf->str[buf->i] = 'f'; buf->str[buf->i + 1] = 'a'; buf->str[buf->i + 2] = 'l'; buf->str[buf->i + 3] = 's';
        buf->str[buf->i + 4] = 'e'; buf->i += 5;
    }
}

#define maybe_comma {\
    if (comma) {\
        put(',');\
    } else {\
        put('{');\
        comma = 1;\
    }\
}

#define object_value {\
    put(':');\
    encode_value(l, buf);\
}

#define empty_array {\
    if ((buf->size - buf->i) < 2) {\
        buf->size *= 2;\
        buf->str = (char *) realloc(buf->str, buf->size + 1);\
    }\
    buf->str[buf->i] = '['; buf->str[buf->i + 1] = ']';\
    buf->i += 2;\
}

static void encode_table(lua_State *l, buf_t *buf)
{
    size_t len;
    const char *str;
    // Check for method
    lua_getfield(l, -1, "to_json");
    if (lua_type(l, -1) == LUA_TFUNCTION) {
        lua_pushvalue(l, -2);
        lua_call(l, 1, 1);
        str = lua_tolstring(l, -1, &len);
        request_space(len * 6 + 2);
        puts(buf, str, len);
        lua_pop(l, 1);
        return;
    }
    lua_pop(l, 1);
    // Encoding table
    lua_pushnil(l);
    int next = lua_next(l, -2);
    if (next) {
        int t = lua_type(l, -2);
        // Array
        if (t == LUA_TNUMBER) {
            double num = lua_tonumber(l, -2);
            if ((int)num == 1) {
                put('[');
                encode_value(l, buf);
                lua_pop(l, 2);
                for (int n = 2;; ++n) {
                    lua_rawgeti(l, -1, n);
                    if (lua_type(l, -1) == LUA_TNIL) {
                        lua_pop(l, 1);
                        break;
                    }
                    put(',');
                    encode_value(l, buf);
                    lua_pop(l, 1);
                }
                put(']');
                return;
            }
        }
        // Hash
        int value_type, comma = 0;
        while (next) {
            value_type = lua_type(l, -1);
            switch (value_type) {
            case LUA_TSTRING:
            case LUA_TNUMBER:
            case LUA_TBOOLEAN:
            case LUA_TTABLE:
                if (t == 0) t = lua_type(l, -2);
                switch (t) {
                    case LUA_TSTRING:
                        maybe_comma;
                        str = lua_tolstring(l, -2, &len);
                        encode_str(l, buf, len, str);
                        object_value;
                        break;
                    case LUA_TNUMBER:
                        maybe_comma;
                        lua_pushvalue(l, -2);
                        str = lua_tolstring(l, -1, &len);
                        encode_str(l, buf, len, str);
                        lua_pop(l, 1);
                        object_value;
                        break;
                    case LUA_TBOOLEAN:
                        maybe_comma;
                        if (lua_toboolean(l, -2)) {
                            if ((buf->size - buf->i) < 6) {
                                buf->size *= 2;
                                buf->str = (char *) realloc(buf->str, buf->size + 1);
                            }
                            buf->str[buf->i] = '\"'; buf->str[buf->i + 1] = 't';
                            buf->str[buf->i + 2] = 'r'; buf->str[buf->i + 3] = 'u';
                            buf->str[buf->i + 4] = 'e'; buf->str[buf->i + 5] = '\"';
                            buf->i += 6;
                        } else {
                            if ((buf->size - buf->i) < 7) {
                                buf->size *= 2;
                                buf->str = (char *) realloc(buf->str, buf->size + 1);
                            }
                            buf->str[buf->i] = '\"'; buf->str[buf->i + 1] = 'f';
                            buf->str[buf->i + 2] = 'a'; buf->str[buf->i + 3] = 'l';
                            buf->str[buf->i + 4] = 's'; buf->str[buf->i + 5] = 'e';
                            buf->str[buf->i + 6] = '\"'; buf->i += 7;
                        }
                        object_value;
                        break;
                    case LUA_TLIGHTUSERDATA:
                        if (lua_touserdata(l, -2) == NULL) {
                            maybe_comma;
                            if ((buf->size - buf->i) < 6) {
                                buf->size *= 2;
                                buf->str = (char *) realloc(buf->str, buf->size + 1);
                            }
                            buf->str[buf->i] = '\"'; buf->str[buf->i + 1] = 'n';
                            buf->str[buf->i + 2] = 'u'; buf->str[buf->i + 3] = 'l';
                            buf->str[buf->i + 4] = 'l'; buf->str[buf->i + 5] = '\"';
                            buf->i += 6;
                            object_value;
                        }
                        break;
                }
            }
            lua_pop(l, 1);
            next = lua_next(l, -2);
            t = 0;
        }
        if (comma) {
            put('}');
        } else {
            empty_array;
        }
    } else {
        empty_array;
    }
}

static void encode_value(lua_State *l, buf_t *buf)
{
    switch (lua_type(l, -1)) {
    case LUA_TSTRING:
        encode_string(l, buf);
        break;
    case LUA_TNUMBER:
        encode_number(l, buf);
        break;
    case LUA_TBOOLEAN:
        encode_boolean(l, buf);
        break;
    case LUA_TTABLE:
        encode_table(l, buf);
        break;
    default:
        put4('n', 'u', 'l', 'l');
    }
}

static int encode(lua_State *l)
{
    buf_t *buf = (buf_t *)lua_touserdata(l, lua_upvalueindex(1));
    buf->i = 0;

    encode_value(l, buf);
    lua_pushlstring(l, buf->str, buf->i);

    return 1;
}

/* ===== INITIALISATION ===== */

#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM < 502
/* Compatibility for Lua 5.1.
 *
 * luaL_setfuncs() is used to create a module table where the functions have
 * strbuf_t as their first upvalue. Code borrowed from Lua 5.2 source. */
static void luaL_setfuncs (lua_State *l, const luaL_Reg *reg, int nup)
{
    int i;

    luaL_checkstack(l, nup, "too many upvalues");
    for (; reg->name != NULL; reg++) {  /* fill the table with given functions */
        for (i = 0; i < nup; i++)  /* copy upvalues to the top */
            lua_pushvalue(l, -nup);
        lua_pushcclosure(l, reg->func, nup);  /* closure with those upvalues */
        lua_setfield(l, -(nup + 2), reg->name);
    }
    lua_pop(l, nup);  /* remove upvalues */
}
#endif

static int free_buf(lua_State *l)
{
    buf_t *buf;

    buf = (buf_t *)lua_touserdata(l, 1);
    if (buf) {
        free(buf->str);
        buf->str = NULL;
    }
    buf = NULL;

    return 0;
}

int luaopen_rjson(lua_State *l) {

    luaL_Reg reg[] = {
        { "encode", encode },
        { "decode", decode },
        { NULL, NULL }
    };

    lua_newtable(l);

    buf_t *buf;
    buf = (buf_t *)lua_newuserdata(l, sizeof(*buf));
    buf->size = 1023;
    buf->str = (char *) malloc(buf->size + 1);

    lua_newtable(l);
    lua_pushcfunction(l, free_buf);
    lua_setfield(l, -2, "__gc");
    lua_setmetatable(l, -2);

    luaL_setfuncs(l, reg, 1);
    
    lua_pushlightuserdata(l, NULL);
    lua_setfield(l, -2, "null");
    
    return 1;
}
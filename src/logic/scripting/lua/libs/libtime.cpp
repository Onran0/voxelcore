#include "engine/Engine.hpp"
#include "api_lua.hpp"
#include <ctime>

using namespace scripting;

static int l_uptime(lua::State* L) {
    return lua::pushnumber(L, engine->getTime().getTime());
}

static int l_delta(lua::State* L) {
    return lua::pushnumber(L, engine->getTime().getDelta());
}

static int l_utc_time(lua::State* L) {
    return lua::pushnumber(L, std::time(nullptr));
}

static int l_local_time(lua::State* L) {
    std::time_t t = std::time(nullptr);

    std::tm gmt_tm{};
    gmtime_s(&gmt_tm, &t);

    std::tm local_tm{};
    localtime_s(&local_tm, &t);

    std::time_t utc_time = std::mktime(&gmt_tm);
    std::time_t local_time = std::mktime(&local_tm);

    std::time_t offset = local_time - utc_time;

    return lua::pushnumber(L, t + offset);
}

static int l_utc_offset(lua::State* L) {
    std::time_t t = std::time(nullptr);

    std::tm gmt_tm{};
    gmtime_s(&gmt_tm, &t);

    std::tm local_tm{};
    localtime_s(&local_tm, &t);

    std::time_t utc_time = std::mktime(&gmt_tm);
    std::time_t local_time = std::mktime(&local_tm);

    std::time_t offset = local_time - utc_time;

    return lua::pushnumber(L, offset);
}

const luaL_Reg timelib[] = {
    {"uptime", lua::wrap<l_uptime>},
    {"delta", lua::wrap<l_delta>},
    {"utc_time", lua::wrap<l_utc_time>},
    {"utc_offset", lua::wrap<l_utc_offset>},
    {"local_time", lua::wrap<l_local_time>},
    {NULL, NULL}
};

typedef struct APIConfig APIConfig;

typedef struct API API;







typedef enum Error { OK = 0, NO_EFFECT = 1, CXX_EXCEPT = 2, DID_NOTHING = 3 } Error;

typedef enum MessageType { Protobuf = 0, Time = 1, } MessageType;



typedef unsigned int busmt_size_t;

typedef const char * cstr;

typedef char * cstr_mut;

typedef APIConfig * const APIConfig_mut;

typedef APIConfig const * const APIConfig_immut;

typedef API * const API_mut;

typedef API const * const API_immut;

typedef void * Data;

typedef void * UserData;

typedef void ( *Listener ) ( cstr type, busmt_size_t payload_len, Data payload, UserData user_data );

typedef void ( *TimeListener ) ( long long time, UserData user_data );

typedef struct ProtobufData {
    cstr signal_type;
    busmt_size_t payload_len;
    Data payload;
} ProtobufData;

typedef struct TimeData {
    long long time;
} TimeData;

typedef struct Message {
    MessageType type;
    union {
        ProtobufData proto_data;
        TimeData time_data;
    };
} Message;



extern __attribute__ ( ( visibility ( "default" ) ) ) APIConfig * busmt_new_config ();

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_delete_config ( APIConfig * cfg, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) void busmt_config_set_uri ( APIConfig_mut cfg, cstr uri );

extern __attribute__ ( ( visibility ( "default" ) ) ) cstr busmt_config_get_uri ( APIConfig_immut cfg );

extern __attribute__ ( ( visibility ( "default" ) ) ) void busmt_config_set_federation_id ( APIConfig_mut cfg, cstr federation_id );

extern __attribute__ ( ( visibility ( "default" ) ) ) cstr busmt_config_get_federation_id ( APIConfig_immut cfg );

extern __attribute__ ( ( visibility ( "default" ) ) ) void busmt_config_set_federate_id ( APIConfig_mut cfg, cstr federate_id );

extern __attribute__ ( ( visibility ( "default" ) ) ) cstr busmt_config_get_federate_id ( APIConfig_immut cfg );

extern __attribute__ ( ( visibility ( "default" ) ) ) void busmt_config_set_polling ( APIConfig_mut cfg, int sync );

extern __attribute__ ( ( visibility ( "default" ) ) ) int busmt_config_get_polling ( APIConfig_immut cfg );

extern __attribute__ ( ( visibility ( "default" ) ) ) void busmt_config_set_timed ( APIConfig_mut cfg, int timed );

extern __attribute__ ( ( visibility ( "default" ) ) ) int busmt_config_get_timed ( APIConfig_immut cfg );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_config_add_proto ( APIConfig_mut cfg, cstr filename, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_config_add_signal ( APIConfig_mut cfg, cstr type, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_new_api ( APIConfig_immut cfg, API ** result, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_delete_api ( API * api, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_api_close ( API * api, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_api_poll ( API_mut api, Message ** message, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_api_listen_signal ( API_mut api, cstr signal_type, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_api_listen_time ( API_mut api, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) long long busmt_api_current_time ( API_immut api );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_api_advance_time ( API_mut api, long long t, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) long long busmt_api_get_advance ( API_immut api );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_api_add_time_listener ( API_mut api, TimeListener listener, UserData user_data, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_api_add_signal_listener ( API_mut api, cstr signal_type, Listener listener, UserData user_data, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) Error busmt_api_send ( API_immut api, cstr type, busmt_size_t payload_len, Data payload, int broadcast, cstr route, cstr_mut * report );

extern __attribute__ ( ( visibility ( "default" ) ) ) void delete_str ( cstr_mut * str );

extern __attribute__ ( ( visibility ( "default" ) ) ) void delete_message ( Message * msg );

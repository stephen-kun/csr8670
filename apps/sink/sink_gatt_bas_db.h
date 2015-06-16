#ifdef GATT_SERVER_BAS_ENABLED

primary_service {
    uuid : 0x180F,
    name : "BATTERY_SERVICE",
    characteristic {
        uuid        : 0x2A19,
        name        : "BATTERY_LEVEL",
        flags       : [ FLAG_IRQ ],
        properties  : [ read , notify ],
        value       : 0x0,
        client_config
        {
            name  : "BATTERY_LEVEL_CLIENT_CONFIG",
            flags : [ FLAG_IRQ , FLAG_DYNLEN ]
        }
    }
},

#endif /* GATT_SERVER_BAS_ENABLED */

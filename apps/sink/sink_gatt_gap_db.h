primary_service {
    uuid : 0x1800,
    name : "GAP_SERVICE",
    characteristic {
        uuid       : 0x2A00,
        name       : "DEVICE_NAME",
        flags      : [ FLAG_IRQ ],
        properties : [ read ]
    },
    characteristic {
        uuid       : 0x2A01,
        name       : "DEVICE_APPEARANCE",
        flags      : [ FLAG_IRQ ],
        properties : [ read ]
    }
}

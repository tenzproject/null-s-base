Config = Config or {}
Config.UsableItems = {
    ["bread"] = {type="hunger", label="Pain",number=20},

    ["water"] = {type="thirst", label="Eau", number=20},

    ["codeinetraitement"] = {type="drug", label="Pochon de Codeine", number=16},

    ["vin"] = {type="drunk", label="Bouteille de vin", number=50},

    ["medikit"] = {type="heal", label="Medikit", number=100, time=7},
    ["bandage"] = {type="heal", label="Bandage", number=50, time=4},
    
    ["camera"] = {type="clientevent", event="null:camera:menu", label="Caméra", notRemove = true},

    ["kevlar"] = {type="armor", label="Kevlar", number=100, time=5},
}
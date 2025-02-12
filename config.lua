Config = {}

local StringCharset = {}
local NumberCharset = {}

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end
for i = 65,  90 do table.insert(StringCharset, string.char(i)) end
for i = 97, 122 do table.insert(StringCharset, string.char(i)) end

Config.RandomStr = function(length)
	if length > 0 then
		return Config.RandomStr(length-1) .. StringCharset[math.random(1, #StringCharset)]
	else
		return ''
	end
end

Config.RandomInt = function(length)
	if length > 0 then
		return Config.RandomInt(length-1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

Config.MaxWeight = 120000

Config.AmmoRounds = {
    pistol_ammo = 12,
    smg_ammo = 30,
    rifle_ammo = 30,
    shotgun_ammo = 8,
    mg_ammo = 54,
}

Config.WeaponOutDict = "reaction@intimidation@1h"
Config.WeaponOutAnim = "intro"
Config.WeaponHideAnim = "outro"

Config.CraftingItems = {
    [1] = {
        name = "lockpick",
        amount = 50,
        info = {},
        costs = {
            ["metalscrap"] = 22,
            ["plastic"] = 32,
        },
        type = "item",
        slot = 1,
        threshold = 0,
        points = 1,
    },
    [2] = {
        name = "screwdriverset",
        amount = 50,
        info = {},
        costs = {
            ["metalscrap"] = 30,
            ["plastic"] = 42,
        },
        type = "item",
        slot = 2,
        threshold = 0,
        points = 2,
    },
    [3] = {
        name = "electronickit",
        amount = 50,
        info = {},
        costs = {
            ["metalscrap"] = 30,
            ["plastic"] = 45,
            ["aluminum"] = 28,
        },
        type = "item",
        slot = 3,
        threshold = 0,
        points = 3,
    },
    [4] = {
        name = "radioscanner",
        amount = 50,
        info = {},
        costs = {
            ["electronickit"] = 2,
            ["plastic"] = 52,
            ["steel"] = 40,
        },
        type = "item",
        slot = 4,
        threshold = 0,
        points = 4,
    },
    [5] = {
        name = "gatecrack",
        amount = 50,
        info = {},
        costs = {
            ["metalscrap"] = 10,
            ["plastic"] = 50,
            ["aluminum"] = 30,
            ["iron"] = 17,
            ["electronickit"] = 1,
        },
        type = "item",
        slot = 5,
        threshold = 120,
        points = 5,
    },
    [6] = {
        name = "handcuffs",
        amount = 50,
        info = {},
        costs = {
            ["metalscrap"] = 36,
            ["steel"] = 24,
            ["aluminum"] = 28,
        },
        type = "item",
        slot = 6,
        threshold = 160,
        points = 6,
    },
    [7] = {
        name = "repairkit",
        amount = 50,
        info = {},
        costs = {
            ["metalscrap"] = 32,
            ["steel"] = 43,
            ["plastic"] = 61,
        },
        type = "item",
        slot = 7,
        threshold = 200,
        points = 7,
    },
    [8] = {
        name = "pistol_ammo",
        amount = 50,
        info = {},
        costs = {
            ["metalscrap"] = 50,
            ["steel"] = 37,
            ["copper"] = 26,
        },
        type = "item",
        slot = 8,
        threshold = 250,
        points = 8,
    },
    [9] = {
        name = "ironoxide",
        amount = 50,
        info = {},
        costs = {
            ["iron"] = 60,
            ["glass"] = 30,
        },
        type = "item",
        slot = 9,
        threshold = 300,
        points = 9,
    },
    [10] = {
        name = "aluminumoxide",
        amount = 50,
        info = {},
        costs = {
            ["aluminum"] = 60,
            ["glass"] = 30,
        },
        type = "item",
        slot = 10,
        threshold = 300,
        points = 10,
    },
    [11] = {
        name = "armor",
        amount = 50,
        info = {},
        costs = {
            ["iron"] = 33,
            ["steel"] = 44,
            ["plastic"] = 55,
            ["aluminum"] = 22,
        },
        type = "item",
        slot = 11,
        threshold = 350,
        points = 11,
    },
    [12] = {
        name = "drill",
        amount = 50,
        info = {},
        costs = {
            ["iron"] = 50,
            ["steel"] = 50,
            ["screwdriverset"] = 3,
            ["advancedlockpick"] = 2,
        },
        type = "item",
        slot = 12,
        threshold = 1750,
        points = 12,
    },
}

Config.AttachmentCrafting = {
    ["location"] = {x = 88.91, y = 3743.88, z = 40.77, h = 66.5, r = 1.0}, 
    ["items"] = {
        [1] = {
            name = "pistol_extendedclip",
            amount = 50,
            info = {},
            costs = {
                ["metalscrap"] = 140,
                ["steel"] = 250,
                ["rubber"] = 60,
            },
            type = "item",
            slot = 1,
            threshold = 0,
            points = 1,
        },
        [2] = {
            name = "pistol_suppressor",
            amount = 50,
            info = {},
            costs = {
                ["metalscrap"] = 165,
                ["steel"] = 285,
                ["rubber"] = 75,
            },
            type = "item",
            slot = 2,
            threshold = 10,
            points = 2,
        },
        [3] = {
            name = "rifle_extendedclip",
            amount = 50,
            info = {},
            costs = {
                ["metalscrap"] = 190,
                ["steel"] = 305,
                ["rubber"] = 85,
                ["smg_extendedclip"] = 1,
            },
            type = "item",
            slot = 7,
            threshold = 25,
            points = 8,
        },
        [4] = {
            name = "rifle_drummag",
            amount = 50,
            info = {},
            costs = {
                ["metalscrap"] = 205,
                ["steel"] = 340,
                ["rubber"] = 110,
                ["smg_extendedclip"] = 2,
            },
            type = "item",
            slot = 8,
            threshold = 50,
            points = 8,
        },
        [5] = {
            name = "smg_flashlight",
            amount = 50,
            info = {},
            costs = {
                ["metalscrap"] = 230,
                ["steel"] = 365,
                ["rubber"] = 130,
            },
            type = "item",
            slot = 3,
            threshold = 75,
            points = 3,
        },
        [6] = {
            name = "smg_extendedclip",
            amount = 50,
            info = {},
            costs = {
                ["metalscrap"] = 255,
                ["steel"] = 390,
                ["rubber"] = 145,
            },
            type = "item",
            slot = 4,
            threshold = 100,
            points = 4,
        },
        [7] = {
            name = "smg_suppressor",
            amount = 50,
            info = {},
            costs = {
                ["metalscrap"] = 270,
                ["steel"] = 435,
                ["rubber"] = 155,
            },
            type = "item",
            slot = 5,
            threshold = 150,
            points = 5,
        },
        [8] = {
            name = "smg_scope",
            amount = 50,
            info = {},
            costs = {
                ["metalscrap"] = 300,
                ["steel"] = 469,
                ["rubber"] = 170,
            },
            type = "item",
            slot = 6,
            threshold = 200,
            points = 6,
        },
    }
}

MaxInventorySlots = 41

BackEngineVehicles = {
    'ninef',
    'adder',
    'vagner',
    't20',
    'infernus',
    'zentorno',
    'reaper',
    'comet2',
    'comet3',
    'jester',
    'jester2',
    'cheetah',
    'cheetah2',
    'prototipo',
    'turismor',
    'pfister811',
    'ardent',
    'nero',
    'nero2',
    'tempesta',
    'vacca',
    'bullet',
    'osiris',
    'entityxf',
    'turismo2',
    'fmj',
    're7b',
    'tyrus',
    'italigtb',
    'penetrator',
    'monroe',
    'ninef2',
    'stingergt',
    'surfer',
    'surfer2',
    'comet3',
}

Config.MaximumAmmoValues = {
    ["pistol"] = 250,
    ["smg"] = 250,
    ["shotgun"] = 200,
    ["rifle"] = 250,
}

Config.worldContainers = {
    [684586828] = { name = 'prop_cs_dumpster_01a', slots = 41 },
    [577432224] = { name = 'p_dumpster_t', slots = 41 },
    [-206690185] = { name = 'prop_dumpster_3a', slots = 41 },
    [682791951] = { name = 'prop_dumpster_4b', slots = 41 },
    [1511880420] = { name = 'prop_dumpster_4a', slots = 41 },
    [-1587184881] = { name = 'prop_snow_dumpster_01', slots = 41 },
    [666561306] = { name = 'prop_dumpster_02a', slots = 41 },
    [-58485588] = { name = 'prop_dumpster_02b', slots = 41 },
    [218085040] = { name = 'prop_dumpster_01a', slots = 41 },
    [1129053052] = { name = 'prop_burgerstand_01', slots = 41 },
    
    [-1472203944] = { name = 'prop_gas_binunit01', slots = 31 },
    [-96647174] = { name = 'prop_recyclebin_05_a', slots = 31 },
    
    [651101403] = { name = 'prop_cs_bin_02', slots = 21 },
    [865150065] = { name = 'prop_gas_smallbin01', slots = 21 },
    [-5943724] = { name = 'prop_bin_beach_01d', slots = 21 },
    [1437508529] = { name = 'prop_bin_01a', slots = 21 },
    [-14708062] = { name = 'prop_recyclebin_04_a', slots = 21 },
    [234941195] = { name = 'prop_bin_beach_01a', slots = 21 },
    [-85604259] = { name = 'prop_recyclebin_02_c', slots = 21 },
    [1380691550] = { name = 'prop_bin_delpiero_b', slots = 21 },
    [1919238784] = { name = 'zprop_bin_01a_old', slots = 21 },
    [-1830793175] = { name = 'prop_bin_10a', slots = 21 },
    [-329415894] = { name = 'prop_bin_10b', slots = 21 },
    [-1426008804] = { name = 'prop_bin_07c', slots = 21 },
    [-341442425] = { name = 'prop_bin_11a', slots = 21 },
    [1143474856] = { name = 'prop_bin_06a', slots = 21 },
    [-1187286639] = { name = 'prop_bin_07d', slots = 21 },
    [1792999139] = { name = 'prop_bin_11b', slots = 21 },
    [-93819890] = { name = 'prop_bin_04a', slots = 21 },
    [673826957] = { name = 'prop_recyclebin_02b', slots = 21 },
    [-317177646] = { name = 'prop_bin_delpiero', slots = 21 },
    [437765445] = { name = 'prop_bin_09a', slots = 21 },
    [-1096777189] = { name = 'prop_bin_08a', slots = 21 },
    [811169045] = { name = 'prop_recyclebin_04_b', slots = 21 },
    [1614656839] = { name = 'prop_bin_02a', slots = 21 },
    [1233216915] = { name = 'prop_recyclebin_02_d', slots = 21 },
    [-413198204] = { name = 'prop_bin_08open', slots = 21 },
    [-2096124444] = { name = 'prop_bin_12a', slots = 21 },
    [375956747] = { name = 'prop_recyclebin_02a', slots = 21 },
    [1329570871] = { name = 'prop_bin_05a', slots = 21 },
    [-228596739] = { name = 'prop_bin_07a', slots = 21 },
    [-115771139] = { name = 'prop_recyclebin_01a', slots = 21 },
    [-246439655] = { name = 'prop_food_bin_01', slots = 21 },
    [74073934] = { name = 'prop_food_bin_02', slots = 21 },
    [274859350] = { name = 'v_serv_tc_bin2_', slots = 21 },
    [751349707] = { name = 'v_serv_tc_bin1_', slots = 21 },
    [173513051] = { name = 'prop_snow_bin_02', slots = 21 },
    [2012837021] = { name = 'prop_snow_bin_01', slots = 21 },
}

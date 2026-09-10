-- Configuration des tâches des employés
-- Permet de configurer les animations, timings, items requis pour chaque tâche

Config.EmployeeTasks = {
    ["water"] = {
        label = "Arroser",
        requiredItem = "water-canister",
        requiredItemCount = 1,
        storageInteraction = true,
        fatigueNeeded = 4,
        animations = {
            storage = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 4000
            },
            work = {
                dict = "amb@medic@standing@kneel@base",
                anim = "base",
                duration = 8000
            }
        },
        timing = {
            pauseAfterTask = 5000,  -- Pause après la tâche (ms)
            walkTimeout = 500        -- Timeout pour la marche (secondes * 10)
        }
    },
    
    ["fertilize"] = {
        label = "Fertiliser",
        requiredItem = "fertilizer",
        requiredItemCount = 1,
        storageInteraction = true,
        fatigueNeeded = 4,
        animations = {
            storage = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 4000
            },
            work = {
                dict = "amb@medic@standing@kneel@base",
                anim = "base",
                duration = 10000
            }
        },
        timing = {
            pauseAfterTask = 5000,
            walkTimeout = 500
        }
    },
    
    ["harvest"] = {
        label = "Récolter",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 10,
        animations = {
            work = {
                dict = "amb@medic@standing@kneel@base",
                anim = "base",
                duration = 12500
            }
        },
        timing = {
            pauseAfterTask = 12500,
            walkTimeout = 500
        }
    },
    
    ["seed"] = {
        label = "Planter une graine",
        requiredItem = "weed-seed-female",
        requiredItemCount = 1,
        storageInteraction = true,
        fatigueNeeded = 5,
        animations = {
            storage = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 4000
            },
            work = {
                dict = "amb@medic@standing@kneel@base",
                anim = "base",
                duration = 6000
            }
        },
        timing = {
            pauseAfterTask = 5000,
            walkTimeout = 500
        }
    },
    
    ["dry_weed"] = {
        label = "Sécher",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 1,
        animations = {
            work = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 1000
            }
        },
        timing = {
            pauseAfterTask = 2000,
            walkTimeout = 500
        }
    },
    
    ["collect_dry"] = {
        label = "Collecter",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 1,
        animations = {
            work = {
                dict = "amb@medic@standing@kneel@base",
                anim = "base",
                duration = 3000
            }
        },
        timing = {
            pauseAfterTask = 15000,
            walkTimeout = 500
        }
    },
    
    ["deposit_dry"] = {
        label = "Déposer",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 1,
        animations = {
            work = {
                dict = "amb@medic@standing@kneel@base",
                anim = "base",
                duration = 3000
            }
        },
        timing = {
            pauseAfterTask = 15000,
            walkTimeout = 500
        }
    },
    
    ["treat_weed"] = {
        label = "Traiter",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 7,
        animations = {
            work = {
                dict = "anim@amb@business@weed@weed_sorting_seated@",
                anim = "sorter_right_sort_v3_sorter02",
                duration = 4750,
                iterations = 5  -- Nombre de fois que l'animation se répète
            }
        },
        timing = {
            pauseAfterTask = 30000,
            walkTimeout = 500
        }
    },

    -- ========== METH TASKS ==========
    ["meth_fill_cuve"] = {
        label = "Remplir la cuve",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = true,
        fatigueNeeded = 5,
        animations = {
            storage = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 4000
            },
            work = {
                dict = "amb@prop_human_bbq@male@idle_a",
                anim = "idle_a",
                duration = 6000
            }
        },
        timing = {
            pauseAfterTask = 5000,
            walkTimeout = 500
        }
    },
    
    ["meth_add_solvant"] = {
        label = "Ajouter le solvant",
        requiredItem = "solvant-meth",
        requiredItemCount = 1,
        storageInteraction = true,
        fatigueNeeded = 5,
        animations = {
            storage = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 4000
            },
            work = {
                dict = "amb@prop_human_bbq@male@idle_a",
                anim = "idle_a",
                duration = 5000
            }
        },
        timing = {
            pauseAfterTask = 5000,
            walkTimeout = 500
        }
    },
    
    ["meth_collect_tray"] = {
        label = "Récupérer un plateau",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 1,
        animations = {
            work = {
                dict = "amb@prop_human_bbq@male@idle_a",
                anim = "idle_a",
                duration = 4000
            }
        },
        timing = {
            pauseAfterTask = 3000,
            walkTimeout = 500
        }
    },
    
    ["meth_load_four"] = {
        label = "Charger le four",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 1,
        animations = {
            work = {
                dict = "amb@prop_human_bbq@male@idle_a",
                anim = "idle_a",
                duration = 5000
            }
        },
        timing = {
            pauseAfterTask = 3000,
            walkTimeout = 500
        }
    },
    
    ["meth_unload_four"] = {
        label = "Décharger le four",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 1,
        animations = {
            work = {
                dict = "amb@prop_human_bbq@male@idle_a",
                anim = "idle_a",
                duration = 5000
            }
        },
        timing = {
            pauseAfterTask = 3000,
            walkTimeout = 500
        }
    },
    
    ["meth_deposit_storage"] = {
        label = "Déposer au stockage",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = false,
        fatigueNeeded = 2,
        animations = {
            work = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 3000
            }
        },
        timing = {
            pauseAfterTask = 5000,
            walkTimeout = 500
        }
    },
    
    ["meth_break_tray"] = {
        label = "Casser et mettre en pochon",
        requiredItem = "meth_tray",  -- Tray to break
        requiredItemCount = 1,
        additionalRequiredItem = "pooch",  -- Pooch needed for packing
        additionalRequiredItemCount = 1,
        storageInteraction = true,
        fatigueNeeded = 5,
        animations = {
            work = {
                dict = "amb@prop_human_bbq@male@idle_a",
                anim = "idle_a",
                duration = 10000  -- Longer animation for combined break+pack
            },
            storage = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 3000
            }
        },
        timing = {
            pauseAfterTask = 3000,
            walkTimeout = 500
        }
    },
    
    ["meth_pack_pooch"] = {
        label = "Mettre en pochon",
        requiredItem = nil,
        requiredItemCount = 0,
        storageInteraction = true,
        fatigueNeeded = 2,
        animations = {
            work = {
                dict = "anim@amb@business@weed@weed_sorting_seated@",
                anim = "sorter_right_sort_v3_sorter02",
                duration = 5000
            },
            storage = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d",
                duration = 2000
            }
        },
        timing = {
            pauseAfterTask = 2000,
            walkTimeout = 500
        }
    }
}

local ENCHANT_REAGENTS = {
  SOUL_DUST = "172230",
  SACRED_SHARD = "172231",
  ETERNAL_CRYSTAL = "172232",

  GLOOM_DUST = "152875",
  UMBRA_SHARD = "152876",
  VEILED_CRYSTAL = "152877",

  ARKANA = "124440",
  LEYLIGHT_SHARD = "124441",
  CHAOS_CRYSTAL = "124442",

  DRAENIC_DUST = "109693",
  LUMINOUS_SHARD = "111245",
  SMALL_LUMINOUS_SHARD = "115502",
  TEMPORAL_CRYSTAL = "113588",
  FRACTURED_TEMPORAL_CRYSTAL = "115504",

  -- Midnight (Quality-12-Tier: materials have quality 13/14 Silver/Gold; 50/50 split for expected value)
  EVERSINGING_DUST_SILVER = "243599",
  EVERSINGING_DUST_GOLD = "243600",
  RADIANT_SHARD_SILVER = "243602",
  RADIANT_SHARD_GOLD = "243603",
  DAWN_CRYSTAL_SILVER = "243605",
  DAWN_CRYSTAL_GOLD = "243606",
}

Auctionator.Enchant.DE_TABLE = {
  [LE_EXPANSION_SHADOWLANDS or LE_EXPANSION_9_0] = {
    [Enum.ItemQuality.Uncommon] = {
      -- This example has 33.3% drop chance of 1, 33.3% drop chance of 2 and a
      -- 33.3% drop chance of 3
      [ENCHANT_REAGENTS.SOUL_DUST] = {0.333, 0.333, 0.333}
    },
    [Enum.ItemQuality.Rare]  = {
      [ENCHANT_REAGENTS.SOUL_DUST]    = {0.49, 0.45},
      [ENCHANT_REAGENTS.SACRED_SHARD] = {0.99}
    },
    [Enum.ItemQuality.Epic] = {
      [ENCHANT_REAGENTS.SACRED_SHARD]    = {0.35},
      [ENCHANT_REAGENTS.ETERNAL_CRYSTAL] = {1},
    }
  },
  [LE_EXPANSION_BATTLE_FOR_AZEROTH] = {
    [Enum.ItemQuality.Uncommon] = {
      [ENCHANT_REAGENTS.GLOOM_DUST] = {0, 0, 0, 0.36, 0.42, 0.22}
    },
    [Enum.ItemQuality.Rare]  = {
      [ENCHANT_REAGENTS.GLOOM_DUST]  = {0.65, 0.35},
      [ENCHANT_REAGENTS.UMBRA_SHARD] = {1}
    },
    [Enum.ItemQuality.Epic] = {
      [ENCHANT_REAGENTS.UMBRA_SHARD]    = {0.42},
      [ENCHANT_REAGENTS.VEILED_CRYSTAL] = {1},
    }
  },
  [LE_EXPANSION_LEGION] = {
    [Enum.ItemQuality.Uncommon] = {[ENCHANT_REAGENTS.ARKANA] = {0, 0, 0, 0.35, 0.38, 0.27}},
    [Enum.ItemQuality.Rare]  = {[ENCHANT_REAGENTS.LEYLIGHT_SHARD] = {1}},
    [Enum.ItemQuality.Epic] = {[ENCHANT_REAGENTS.CHAOS_CRYSTAL] = {1}},
  },
  [LE_EXPANSION_WARLORDS_OF_DRAENOR] = {
    [Enum.ItemQuality.Uncommon] = {[ENCHANT_REAGENTS.DRAENIC_DUST] = {0.21, 0.34, 0.24, 0.21}},
    [Enum.ItemQuality.Rare]  = {
      [ENCHANT_REAGENTS.DRAENIC_DUST] = {0, 0, 0, 0, 0.11, 0.11, 0.12, 0.19, 0.7, 0.05, 0.05, 0.07},
      [ENCHANT_REAGENTS.LUMINOUS_SHARD] = {0.1},
      [ENCHANT_REAGENTS.SMALL_LUMINOUS_SHARD] = {0, 0, 0.007, 0.012, 0.06, 0.011},
      [ENCHANT_REAGENTS.TEMPORAL_CRYSTAL] = {0.03},
      [ENCHANT_REAGENTS.FRACTURED_TEMPORAL_CRYSTAL] = {0, 0, 0.03},
    },
    [Enum.ItemQuality.Epic] = {
      [ENCHANT_REAGENTS.TEMPORAL_CRYSTAL] = {0.59},
      [ENCHANT_REAGENTS.FRACTURED_TEMPORAL_CRYSTAL] = {0, 0, 0.41},
    },
  },
  -- Midnight (LE_EXPANSION_MIDNIGHT or 11). Materials have quality 13/14 (Silver/Gold).
  -- Silver/Gold splits are hypothetical; reality depends on skill and specialization, which are not implemented.
  [LE_EXPANSION_MIDNIGHT or 11] = {
    [Enum.ItemQuality.Uncommon] = {
      [ENCHANT_REAGENTS.EVERSINGING_DUST_SILVER] = {0.1665, 0.1665, 0.1665},
      [ENCHANT_REAGENTS.EVERSINGING_DUST_GOLD] = {0.1665, 0.1665, 0.1665},
    },
    [Enum.ItemQuality.Rare] = {
      [ENCHANT_REAGENTS.RADIANT_SHARD_SILVER] = {0.5},
      [ENCHANT_REAGENTS.RADIANT_SHARD_GOLD] = {0.5},
    },
    [Enum.ItemQuality.Epic] = {
      [ENCHANT_REAGENTS.DAWN_CRYSTAL_SILVER] = {0.75},
      [ENCHANT_REAGENTS.DAWN_CRYSTAL_GOLD] = {0.25},
    }
  },
}

#!/usr/bin/env python3
"""
Deterministic event generator for Faith Empire Sim.
Generates 200+ events with 10+ event chains.
Run: python3 Tools/generate_events.py
Output: Resources/Events/events_pack.json
"""

import json
import random
import os

random.seed(12345)  # Deterministic

events = []
event_id_counter = [0]

def next_id(prefix="evt"):
    event_id_counter[0] += 1
    return f"{prefix}_{event_id_counter[0]:04d}"

def make_event(title, description, choices, conditions=None, weight=10, cooldown=5):
    eid = next_id()
    ev = {
        "id": eid,
        "title": title,
        "description": description,
        "choices": choices,
        "conditions": conditions or {},
        "weight": weight,
        "cooldown": cooldown,
    }
    events.append(ev)
    return eid

def make_chain_event(title, description, choices, conditions=None, weight=0, cooldown=3):
    """Chain events have weight 0 so they only trigger via next_event_id."""
    eid = next_id("chain")
    ev = {
        "id": eid,
        "title": title,
        "description": description,
        "choices": choices,
        "conditions": conditions or {},
        "weight": weight,
        "cooldown": cooldown,
    }
    events.append(ev)
    return eid

# ============================================================
# CHAIN 1: The Prophet's Vision (3 events)
# ============================================================
c1_3 = make_chain_event(
    "The Prophet's Final Revelation",
    "Your prophet emerges from meditation with blazing eyes. 'I have seen the truth — our faith shall reshape the world, but only if we act NOW.'",
    [
        {"text": "Proclaim a Great Crusade", "effects": {"authority": 15, "militarism": 10, "gold": -100}},
        {"text": "Proclaim an Age of Enlightenment", "effects": {"authority": 10, "knowledge": 15, "education_all": 5}},
        {"text": "Proclaim the Path of Humility", "effects": {"authority": 5, "charity": 15, "legitimacy": 10}},
    ]
)
c1_2 = make_chain_event(
    "The Prophet's Trial",
    "Your prophet retreats into the wilderness for 40 days. Followers grow anxious. Some begin to doubt.",
    [
        {"text": "Send disciples to watch over them", "effects": {"authority": 5, "gold": -20}, "next_event_id": c1_3},
        {"text": "Let them face the trial alone", "effects": {"authority": -5, "legitimacy": 5}, "next_event_id": c1_3},
    ]
)
c1_1 = make_event(
    "The Prophet's Vision",
    "Your spiritual leader claims to have received a divine vision during prayer. The faithful are stirred.",
    [
        {"text": "Announce the vision publicly", "effects": {"authority": 10, "spread_rate": 2}, "next_event_id": c1_2},
        {"text": "Keep it secret among the inner circle", "effects": {"authority": 5, "legitimacy": 5}, "next_event_id": c1_2},
        {"text": "Dismiss it as a fever dream", "effects": {"authority": -10}},
    ],
    conditions={"min_turn": 5},
    weight=15
)

# ============================================================
# CHAIN 2: The Heretic Scholar (3 events)
# ============================================================
c2_3 = make_chain_event(
    "The Scholar's Legacy",
    "The scholar's writings have spread far. They challenge core tenets but also attract intellectuals to your faith.",
    [
        {"text": "Incorporate the teachings", "effects": {"knowledge": 10, "tolerance": 10, "heresy_all": 0.02}},
        {"text": "Burn the manuscripts", "effects": {"authority": 10, "knowledge": -5, "heresy_all": -0.03}},
    ]
)
c2_2 = make_chain_event(
    "The Scholar's Debate",
    "The scholar challenges your high priest to a public theological debate. The crowd gathers.",
    [
        {"text": "Accept the debate", "effects": {"knowledge": 5, "legitimacy": 5}, "next_event_id": c2_3},
        {"text": "Refuse and denounce them", "effects": {"authority": 5, "knowledge": -3}, "next_event_id": c2_3},
    ]
)
c2_1 = make_event(
    "The Heretic Scholar",
    "A brilliant but controversial scholar has begun teaching alternative interpretations of your sacred texts.",
    [
        {"text": "Invite them to discuss", "effects": {"knowledge": 5, "tolerance": 5}, "next_event_id": c2_2},
        {"text": "Have them arrested", "effects": {"authority": 5, "knowledge": -5, "stability_all": -2}},
        {"text": "Ignore them", "effects": {}},
    ],
    conditions={"min_turn": 10},
    weight=12
)

# ============================================================
# CHAIN 3: The Plague (4 events)
# ============================================================
c3_4 = make_chain_event(
    "Plague's End",
    "The plague has finally subsided. Survivors look to your faith for meaning in their suffering.",
    [
        {"text": "Declare divine mercy", "effects": {"authority": 15, "spread_rate": 5, "legitimacy": 10}},
        {"text": "Claim divine punishment for sin", "effects": {"authority": 10, "stability_all": -3}},
    ]
)
c3_3 = make_chain_event(
    "The Plague Spreads",
    "The disease has reached multiple cities. Panic grips the population. Many turn to faith for salvation.",
    [
        {"text": "Open healing temples", "effects": {"gold": -80, "spread_rate": 5, "charity": 5}, "next_event_id": c3_4},
        {"text": "Quarantine the faithful", "effects": {"stability_all": -5, "security_all": 3}, "next_event_id": c3_4},
    ]
)
c3_2 = make_chain_event(
    "Plague Response",
    "Your advisors urge immediate action. The sick are multiplying.",
    [
        {"text": "Pray for divine intervention", "effects": {"ritual": 5, "authority": 5}, "next_event_id": c3_3},
        {"text": "Send healers and supplies", "effects": {"gold": -50, "charity": 10}, "next_event_id": c3_3},
    ]
)
c3_1 = make_event(
    "The Great Plague",
    "A terrible disease has broken out in one of the cities. People are dying by the dozens. They cry out for help.",
    [
        {"text": "Investigate the source", "effects": {"knowledge": 3}, "next_event_id": c3_2},
        {"text": "Seal the city", "effects": {"security_all": 5, "stability_all": -3}, "next_event_id": c3_2},
    ],
    conditions={"min_turn": 15},
    weight=10
)

# ============================================================
# CHAIN 4: The Holy Relic (3 events)
# ============================================================
c4_3 = make_chain_event(
    "The Relic's Power",
    "Pilgrims flock to see the relic. Miracles are reported. Your faith's influence grows tremendously.",
    [
        {"text": "Build a grand shrine", "effects": {"gold": -150, "authority": 20, "spread_rate": 8}},
        {"text": "Tour the relic through cities", "effects": {"gold": -50, "spread_rate": 12}},
    ]
)
c4_2 = make_chain_event(
    "Authenticating the Relic",
    "Scholars examine the relic. Some claim it's genuine, others say it's a forgery. The debate could shake faith.",
    [
        {"text": "Declare it authentic by divine authority", "effects": {"authority": 10}, "next_event_id": c4_3},
        {"text": "Allow scholarly examination", "effects": {"knowledge": 10, "legitimacy": 5}, "next_event_id": c4_3},
    ]
)
c4_1 = make_event(
    "Discovery of a Holy Relic",
    "Excavators have unearthed what appears to be an ancient artifact of immense spiritual significance.",
    [
        {"text": "Claim it for the faith", "effects": {"authority": 5}, "next_event_id": c4_2},
        {"text": "Study it carefully first", "effects": {"knowledge": 5}, "next_event_id": c4_2},
        {"text": "Dismiss it as mundane", "effects": {"legitimacy": -5}},
    ],
    conditions={"min_turn": 8},
    weight=12
)

# ============================================================
# CHAIN 5: The Rival Faith (3 events)
# ============================================================
c5_3 = make_chain_event(
    "Rival Faith Resolution",
    "The confrontation with the rival faith reaches a critical point. Your followers demand decisive action.",
    [
        {"text": "Absorb their best ideas", "effects": {"tolerance": 15, "knowledge": 5, "heresy_all": 0.03}},
        {"text": "Crush them utterly", "effects": {"militarism": 10, "authority": 10, "stability_all": -5}},
        {"text": "Propose coexistence", "effects": {"tolerance": 10, "legitimacy": 10}},
    ]
)
c5_2 = make_chain_event(
    "The Rival Grows Bold",
    "The rival faith has gained a significant following. Their priests openly challenge your authority in the streets.",
    [
        {"text": "Challenge them to a theological contest", "effects": {"knowledge": 5}, "next_event_id": c5_3},
        {"text": "Mobilize the faithful", "effects": {"militarism": 5, "authority": 5}, "next_event_id": c5_3},
    ]
)
c5_1 = make_event(
    "A Rival Faith Emerges",
    "A charismatic preacher has begun spreading a competing religion. They claim divine revelation of their own.",
    [
        {"text": "Monitor them closely", "effects": {"knowledge": 3}, "next_event_id": c5_2},
        {"text": "Send missionaries to counter them", "effects": {"gold": -30, "spread_rate": 3}, "next_event_id": c5_2},
    ],
    conditions={"min_turn": 20},
    weight=10
)

# ============================================================
# CHAIN 6: Royal Conversion (3 events)
# ============================================================
c6_3 = make_chain_event(
    "The Kingdom Transforms",
    "The converted kingdom has fully embraced your faith. Their armies now fly your banners alongside their own.",
    [
        {"text": "Demand tribute", "effects": {"gold": 100, "authority": 5}},
        {"text": "Form a holy alliance", "effects": {"legitimacy": 15, "spread_rate": 5}},
    ]
)
c6_2 = make_chain_event(
    "Royal Baptism",
    "The king's conversion ceremony is a grand affair. Nobles are divided — some follow willingly, others seethe.",
    [
        {"text": "Grand public ceremony", "effects": {"authority": 10, "spread_rate": 5}, "next_event_id": c6_3},
        {"text": "Private ceremony for safety", "effects": {"authority": 5, "security_all": 3}, "next_event_id": c6_3},
    ]
)
c6_1 = make_event(
    "A King Considers Conversion",
    "The ruler of a powerful kingdom has expressed interest in converting to your faith. This could change everything.",
    [
        {"text": "Send your best theologian", "effects": {"gold": -40, "knowledge": 3}, "next_event_id": c6_2},
        {"text": "Offer political advantages", "effects": {"gold": -80, "commerce": 5}, "next_event_id": c6_2},
    ],
    conditions={"min_faith_spread": 10, "min_turn": 25},
    weight=8
)

# ============================================================
# CHAIN 7: The Sacred Text (3 events)
# ============================================================
c7_3 = make_chain_event(
    "The Canon Established",
    "The sacred text is complete. It becomes the foundation of your faith's teaching for generations to come.",
    [
        {"text": "Distribute freely to all", "effects": {"knowledge": 10, "spread_rate": 8, "gold": -60}},
        {"text": "Keep it for the clergy only", "effects": {"authority": 15, "knowledge": -5}},
    ]
)
c7_2 = make_chain_event(
    "The Scribes' Debate",
    "Different scribes have produced varying versions of the text. Which interpretation becomes canon?",
    [
        {"text": "The literal interpretation", "effects": {"ritual": 10, "tolerance": -5}, "next_event_id": c7_3},
        {"text": "The metaphorical interpretation", "effects": {"knowledge": 10, "tolerance": 5}, "next_event_id": c7_3},
        {"text": "A harmonized version", "effects": {"legitimacy": 5}, "next_event_id": c7_3},
    ]
)
c7_1 = make_event(
    "Writing the Sacred Text",
    "Your scholars propose codifying your faith's teachings into a definitive holy book.",
    [
        {"text": "Commission the work", "effects": {"gold": -60, "knowledge": 5}, "next_event_id": c7_2},
        {"text": "The faith needs no book", "effects": {"ritual": 5, "authority": -5}},
    ],
    conditions={"min_turn": 12},
    weight=12
)

# ============================================================
# CHAIN 8: The Martyr (2 events)
# ============================================================
c8_2 = make_chain_event(
    "The Martyr's Legacy",
    "Stories of the martyr spread like wildfire. Converts flock to your banner. But some question if the sacrifice was necessary.",
    [
        {"text": "Canonize the martyr", "effects": {"authority": 15, "spread_rate": 10, "legitimacy": 10}},
        {"text": "Honor them quietly", "effects": {"legitimacy": 10, "stability_all": 3}},
    ]
)
c8_1 = make_event(
    "A Faithful Martyr",
    "One of your devoted followers has been executed by a hostile kingdom for refusing to renounce the faith.",
    [
        {"text": "Declare them a saint", "effects": {"authority": 10}, "next_event_id": c8_2},
        {"text": "Demand justice from the kingdom", "effects": {"militarism": 5, "gold": -20}, "next_event_id": c8_2},
        {"text": "Use their sacrifice as propaganda", "effects": {"spread_rate": 5}, "next_event_id": c8_2},
    ],
    conditions={"min_turn": 15},
    weight=10
)

# ============================================================
# CHAIN 9: The Temple Project (3 events)
# ============================================================
c9_3 = make_chain_event(
    "The Grand Temple Complete",
    "The temple stands as the greatest monument to your faith. Pilgrims come from across the world to marvel at it.",
    [
        {"text": "Declare it the center of the faith", "effects": {"authority": 20, "spread_rate": 10, "legitimacy": 15}},
        {"text": "Dedicate it to all seekers of truth", "effects": {"tolerance": 15, "spread_rate": 8}},
    ]
)
c9_2 = make_chain_event(
    "Temple Construction Troubles",
    "The temple project faces setbacks. Workers demand more pay, and the design is more ambitious than expected.",
    [
        {"text": "Increase funding", "effects": {"gold": -100}, "next_event_id": c9_3},
        {"text": "Scale down the design", "effects": {"gold": -30, "authority": -5}, "next_event_id": c9_3},
        {"text": "Use faithful volunteers", "effects": {"stability_all": -3, "charity": 5}, "next_event_id": c9_3},
    ]
)
c9_1 = make_event(
    "The Grand Temple Project",
    "Your architects propose building a magnificent temple that would be the wonder of the world.",
    [
        {"text": "Approve the project", "effects": {"gold": -200, "authority": 5}, "next_event_id": c9_2},
        {"text": "Build something modest instead", "effects": {"gold": -50, "austerity": 5}},
    ],
    conditions={"min_gold": 200, "min_turn": 20},
    weight=8
)

# ============================================================
# CHAIN 10: The Inquisition (3 events)
# ============================================================
c10_3 = make_chain_event(
    "Inquisition Aftermath",
    "The inquisition has ended. Order is restored, but at what cost? The faithful are divided.",
    [
        {"text": "Declare victory over heresy", "effects": {"authority": 15, "heresy_all": -0.05}},
        {"text": "Show mercy to the accused", "effects": {"tolerance": 10, "legitimacy": 10, "heresy_all": -0.02}},
    ]
)
c10_2 = make_chain_event(
    "The Inquisition Intensifies",
    "Your inquisitors have uncovered a vast network of heresy. Hundreds stand accused. The people tremble.",
    [
        {"text": "Public trials for all", "effects": {"authority": 10, "stability_all": -8}, "next_event_id": c10_3},
        {"text": "Target only the leaders", "effects": {"authority": 5, "stability_all": -3}, "next_event_id": c10_3},
    ]
)
c10_1 = make_event(
    "Call for Inquisition",
    "Heresy festers in your domain. Your advisors recommend establishing a formal inquisition to root out false beliefs.",
    [
        {"text": "Establish the Inquisition", "effects": {"authority": 10, "stability_all": -5}, "next_event_id": c10_2},
        {"text": "Use persuasion instead", "effects": {"tolerance": 5, "charity": 5}},
    ],
    conditions={"min_turn": 18},
    weight=10
)

# ============================================================
# CHAIN 11: The Merchant's Offer (2 events)
# ============================================================
c11_2 = make_chain_event(
    "Trade Route Established",
    "The merchant network is thriving. Gold flows and your faith travels with every caravan.",
    [
        {"text": "Tax the routes heavily", "effects": {"gold": 80, "commerce": -5}},
        {"text": "Let trade flow freely", "effects": {"gold": 40, "spread_rate": 5, "commerce": 10}},
    ]
)
c11_1 = make_event(
    "The Merchant's Offer",
    "A wealthy merchant guild offers to fund your faith's expansion in exchange for favorable trade rights.",
    [
        {"text": "Accept the deal", "effects": {"gold": 100, "commerce": 10}, "next_event_id": c11_2},
        {"text": "Reject worldly temptation", "effects": {"austerity": 10, "authority": 5}},
    ],
    conditions={"min_turn": 8},
    weight=12
)

# ============================================================
# STANDALONE EVENTS (to reach 200+)
# ============================================================

# Template categories
faith_events = [
    ("Pilgrimage Season", "Faithful from across the land embark on pilgrimage. The roads are filled with the devoted.", [
        {"text": "Organize grand processions", "effects": {"gold": -30, "spread_rate": 3, "authority": 5}},
        {"text": "Tax the pilgrims", "effects": {"gold": 50, "legitimacy": -5}},
        {"text": "Join the pilgrimage personally", "effects": {"authority": 10, "ritual": 5}},
    ]),
    ("A Child Prodigy", "A young child displays remarkable spiritual gifts, speaking of visions and performing apparent miracles.", [
        {"text": "Declare them blessed", "effects": {"authority": 5, "spread_rate": 3}},
        {"text": "Test them rigorously", "effects": {"knowledge": 5}},
        {"text": "Dismiss as coincidence", "effects": {"legitimacy": -3}},
    ]),
    ("Temple Vandalism", "Unknown assailants have desecrated one of your temples. The faithful are outraged.", [
        {"text": "Hunt the culprits", "effects": {"security_all": 3, "gold": -20}},
        {"text": "Rebuild grander than before", "effects": {"gold": -50, "authority": 5}},
        {"text": "Turn the other cheek", "effects": {"tolerance": 5, "charity": 5}},
    ]),
    ("Mystical Phenomenon", "Strange lights appear over a holy site. Crowds gather, interpreting it as a divine sign.", [
        {"text": "Proclaim a miracle", "effects": {"authority": 8, "spread_rate": 3}},
        {"text": "Investigate scientifically", "effects": {"knowledge": 8}},
        {"text": "Warn against superstition", "effects": {"tolerance": 3, "knowledge": 3}},
    ]),
    ("Schismatic Preacher", "A popular preacher begins teaching doctrines that differ from official canon.", [
        {"text": "Debate them publicly", "effects": {"knowledge": 5, "legitimacy": 3}},
        {"text": "Excommunicate them", "effects": {"authority": 5, "heresy_all": -0.01}},
        {"text": "Incorporate their ideas", "effects": {"tolerance": 5, "heresy_all": 0.02}},
    ]),
]

political_events = [
    ("Noble Conversion", "A prominent noble has converted to your faith, bringing many followers.", [
        {"text": "Welcome them grandly", "effects": {"gold": -20, "spread_rate": 3, "authority": 3}},
        {"text": "Test their sincerity", "effects": {"knowledge": 3, "legitimacy": 3}},
    ]),
    ("Royal Wedding", "A royal marriage between two kingdoms is planned. They seek your faith's blessing.", [
        {"text": "Bless the union", "effects": {"legitimacy": 5, "authority": 3}},
        {"text": "Demand religious concessions", "effects": {"authority": 8, "legitimacy": -3}},
        {"text": "Refuse unless both convert", "effects": {"authority": 5, "spread_rate": 2}},
    ]),
    ("Border Dispute", "Two kingdoms quarrel over territory. Both sides appeal to your faith for mediation.", [
        {"text": "Mediate fairly", "effects": {"legitimacy": 10, "authority": 5}},
        {"text": "Favor the more faithful side", "effects": {"authority": 5, "spread_rate": 2}},
        {"text": "Stay out of politics", "effects": {"tolerance": 3}},
    ]),
    ("Tax Revolt", "Peasants in a faithful region revolt against heavy taxes. They invoke your teachings of charity.", [
        {"text": "Support the peasants", "effects": {"charity": 10, "legitimacy": 5, "stability_all": -3}},
        {"text": "Urge obedience to authority", "effects": {"authority": 5, "stability_all": 3}},
        {"text": "Negotiate a compromise", "effects": {"stability_all": 2, "legitimacy": 3}},
    ]),
    ("Diplomatic Mission", "A foreign kingdom sends envoys seeking to learn about your faith.", [
        {"text": "Welcome them warmly", "effects": {"tolerance": 5, "spread_rate": 3}},
        {"text": "Convert them aggressively", "effects": {"spread_rate": 5, "tolerance": -3}},
    ]),
]

war_events = [
    ("Warrior Monks", "Devout warriors seek to form a holy military order dedicated to defending the faith.", [
        {"text": "Approve the order", "effects": {"militarism": 10, "security_all": 5, "gold": -40}},
        {"text": "Refuse — faith needs no swords", "effects": {"tolerance": 5, "charity": 5}},
    ]),
    ("War Refugees", "Refugees from a nearby conflict flood into faithful cities, straining resources.", [
        {"text": "Shelter them all", "effects": {"gold": -60, "charity": 10, "spread_rate": 3}},
        {"text": "Accept only the faithful", "effects": {"authority": 3, "tolerance": -5}},
        {"text": "Turn them away", "effects": {"gold": 10, "legitimacy": -5}},
    ]),
    ("Mercenary Offer", "A band of mercenaries offers their swords in service of your faith — for a price.", [
        {"text": "Hire them", "effects": {"gold": -80, "militarism": 5, "security_all": 5}},
        {"text": "Decline", "effects": {}},
    ]),
    ("Victory Celebration", "Your forces have won a significant battle. The faithful rejoice.", [
        {"text": "Grand celebration", "effects": {"gold": -30, "authority": 5, "stability_all": 3}},
        {"text": "Solemn memorial", "effects": {"legitimacy": 5, "charity": 3}},
    ]),
    ("Fortress of Faith", "Engineers propose building a great fortress to protect a holy site.", [
        {"text": "Build it", "effects": {"gold": -120, "security_all": 8}},
        {"text": "Faith is our shield", "effects": {"authority": 3, "ritual": 3}},
    ]),
]

economy_events = [
    ("Bountiful Harvest", "The harvest this year is exceptionally abundant. Farmers praise your faith's blessings.", [
        {"text": "Declare a festival", "effects": {"gold": 20, "stability_all": 3, "spread_rate": 2}},
        {"text": "Store for lean times", "effects": {"gold": 40, "security_all": 2}},
    ]),
    ("Famine", "Crops have failed across the region. People are starving and desperate.", [
        {"text": "Open granaries", "effects": {"gold": -60, "charity": 10, "stability_all": 3}},
        {"text": "Ration carefully", "effects": {"gold": -20, "stability_all": -3}},
        {"text": "Pray for rain", "effects": {"ritual": 5, "authority": 3}},
    ]),
    ("Gold Mine Discovered", "A rich gold mine has been found in territory controlled by the faithful.", [
        {"text": "Claim it for the faith", "effects": {"gold": 100, "authority": 3}},
        {"text": "Share with the local kingdom", "effects": {"gold": 50, "legitimacy": 5}},
    ]),
    ("Trade Disruption", "Bandits have been attacking trade caravans, disrupting commerce.", [
        {"text": "Send patrols", "effects": {"gold": -30, "security_all": 5}},
        {"text": "Negotiate with the bandits", "effects": {"gold": -20, "stability_all": 2}},
    ]),
    ("Wealthy Benefactor", "An incredibly wealthy patron wishes to donate to your faith.", [
        {"text": "Accept gratefully", "effects": {"gold": 150}},
        {"text": "Accept but redistribute to poor", "effects": {"gold": 50, "charity": 15, "spread_rate": 3}},
    ]),
]

culture_events = [
    ("Sacred Music", "Composers have created beautiful hymns that move all who hear them.", [
        {"text": "Standardize the hymnal", "effects": {"ritual": 5, "spread_rate": 2}},
        {"text": "Allow creative freedom", "effects": {"tolerance": 5, "knowledge": 3}},
    ]),
    ("Ancient Ruins", "Explorers discover ruins of an ancient civilization with mysterious inscriptions.", [
        {"text": "Study the inscriptions", "effects": {"knowledge": 10}},
        {"text": "Claim them as proof of your faith's antiquity", "effects": {"authority": 5, "legitimacy": 5}},
        {"text": "Seal the ruins", "effects": {"security_all": 2}},
    ]),
    ("Festival of Lights", "The faithful wish to establish an annual festival celebrating illumination and truth.", [
        {"text": "Grand festival", "effects": {"gold": -40, "ritual": 10, "spread_rate": 3}},
        {"text": "Modest observance", "effects": {"austerity": 5, "ritual": 3}},
    ]),
    ("Foreign Philosophy", "Scholars bring knowledge of foreign philosophies that could enrich or challenge your faith.", [
        {"text": "Study and integrate", "effects": {"knowledge": 10, "tolerance": 5}},
        {"text": "Ban foreign ideas", "effects": {"authority": 5, "knowledge": -5}},
    ]),
    ("Artistic Renaissance", "A wave of artistic creativity sweeps through faithful communities.", [
        {"text": "Commission sacred art", "effects": {"gold": -50, "spread_rate": 5, "ritual": 5}},
        {"text": "Art is vanity", "effects": {"austerity": 5}},
    ]),
]

disaster_events = [
    ("Earthquake", "A powerful earthquake devastates several cities. The faithful look to you for guidance.", [
        {"text": "Lead relief efforts", "effects": {"gold": -80, "charity": 10, "legitimacy": 10}},
        {"text": "Declare divine warning", "effects": {"authority": 10, "stability_all": -5}},
    ]),
    ("Flood", "Severe flooding destroys homes and farmland. Many are left homeless.", [
        {"text": "Build shelters", "effects": {"gold": -50, "charity": 8, "stability_all": 2}},
        {"text": "Pray for deliverance", "effects": {"ritual": 5, "authority": 3}},
    ]),
    ("Eclipse", "A solar eclipse terrifies the population. Superstition runs rampant.", [
        {"text": "Explain it as natural", "effects": {"knowledge": 8, "authority": -3}},
        {"text": "Interpret it as a sign", "effects": {"authority": 8, "ritual": 5}},
    ]),
    ("Drought", "A prolonged drought threatens agriculture and water supplies.", [
        {"text": "Organize water rationing", "effects": {"stability_all": -3, "security_all": 3}},
        {"text": "Conduct rain ceremonies", "effects": {"ritual": 8, "authority": 3}},
    ]),
    ("Locust Swarm", "A massive swarm of locusts devours crops across multiple regions.", [
        {"text": "Distribute stored grain", "effects": {"gold": -40, "charity": 8}},
        {"text": "Fast and pray", "effects": {"austerity": 8, "ritual": 5}},
    ]),
]

internal_events = [
    ("Corruption Scandal", "High-ranking clergy members are found to be embezzling faith funds.", [
        {"text": "Public punishment", "effects": {"authority": 5, "legitimacy": 5, "stability_all": -2}},
        {"text": "Quiet removal", "effects": {"stability_all": 2, "legitimacy": -3}},
        {"text": "Reform the system", "effects": {"knowledge": 5, "gold": -30}},
    ]),
    ("Succession Crisis", "The head of a major temple has died without naming a successor.", [
        {"text": "Appoint someone loyal", "effects": {"authority": 5}},
        {"text": "Hold elections", "effects": {"tolerance": 5, "legitimacy": 5}},
    ]),
    ("Theological Dispute", "Scholars disagree on a fundamental point of doctrine. The debate grows heated.", [
        {"text": "Convene a council", "effects": {"knowledge": 8, "authority": 3}},
        {"text": "Rule by decree", "effects": {"authority": 8, "knowledge": -3}},
        {"text": "Allow multiple interpretations", "effects": {"tolerance": 8, "heresy_all": 0.01}},
    ]),
    ("Youth Movement", "Young believers are pushing for reform and modernization of the faith.", [
        {"text": "Embrace change", "effects": {"tolerance": 8, "knowledge": 5, "authority": -3}},
        {"text": "Maintain tradition", "effects": {"ritual": 5, "authority": 5}},
    ]),
    ("Monastic Order", "Devout followers wish to establish a contemplative monastic order.", [
        {"text": "Approve and fund", "effects": {"gold": -40, "knowledge": 8, "austerity": 5}},
        {"text": "The faith is lived in the world", "effects": {"commerce": 3, "charity": 3}},
    ]),
]

# More variety
misc_events = [
    ("Strange Omen", "A two-headed calf is born in a faithful village. The people see it as an omen.", [
        {"text": "Good omen — celebrate", "effects": {"authority": 3, "spread_rate": 2}},
        {"text": "Bad omen — purify the village", "effects": {"ritual": 5, "stability_all": -2}},
        {"text": "It's just nature", "effects": {"knowledge": 3}},
    ]),
    ("Printing Revolution", "A new method of copying texts quickly has been developed.", [
        {"text": "Use it to spread scripture", "effects": {"gold": -30, "spread_rate": 8, "knowledge": 5}},
        {"text": "Control its use carefully", "effects": {"authority": 5}},
    ]),
    ("Holy Spring Discovered", "A spring with seemingly healing waters has been found.", [
        {"text": "Declare it holy", "effects": {"authority": 5, "spread_rate": 5, "ritual": 5}},
        {"text": "Study the waters", "effects": {"knowledge": 8}},
    ]),
    ("Ambassador's Gift", "A foreign ruler sends lavish gifts seeking your faith's favor.", [
        {"text": "Accept with honor", "effects": {"gold": 60, "legitimacy": 3}},
        {"text": "Return them — we cannot be bought", "effects": {"austerity": 5, "authority": 5}},
    ]),
    ("Cemetery Miracle", "A faithful follower reportedly rose from the dead, then died again peacefully.", [
        {"text": "Investigate and proclaim", "effects": {"authority": 8, "spread_rate": 5}},
        {"text": "Treat it skeptically", "effects": {"knowledge": 5, "authority": -3}},
    ]),
    ("Starving Beggars", "Masses of starving beggars gather outside your temples seeking aid.", [
        {"text": "Feed them all", "effects": {"gold": -40, "charity": 10, "legitimacy": 5}},
        {"text": "Teach them to fish", "effects": {"education_all": 3, "knowledge": 3}},
    ]),
    ("Secret Society", "Reports indicate a secret society working against your faith from within.", [
        {"text": "Root them out", "effects": {"security_all": 5, "stability_all": -3, "gold": -30}},
        {"text": "Infiltrate them", "effects": {"knowledge": 5, "security_all": 3}},
    ]),
    ("Miracle Healer", "A person claiming to heal through faith alone draws massive crowds.", [
        {"text": "Endorse them", "effects": {"spread_rate": 5, "authority": 3}},
        {"text": "Test their claims", "effects": {"knowledge": 5}},
        {"text": "Denounce as fraud", "effects": {"authority": 3, "spread_rate": -2}},
    ]),
    ("Astronomical Discovery", "Scholars make a remarkable discovery about the stars.", [
        {"text": "Incorporate into theology", "effects": {"knowledge": 8, "ritual": 3}},
        {"text": "Suppress the findings", "effects": {"authority": 3, "knowledge": -5}},
    ]),
    ("Foreign Missionary", "Missionaries from a distant land arrive preaching a strange faith.", [
        {"text": "Welcome and debate", "effects": {"tolerance": 5, "knowledge": 5}},
        {"text": "Expel them", "effects": {"authority": 3, "tolerance": -3}},
    ]),
    ("Ancient Prophecy", "An ancient prophecy is discovered that seems to predict your faith's rise.", [
        {"text": "Publicize it widely", "effects": {"authority": 8, "spread_rate": 5}},
        {"text": "Verify its authenticity", "effects": {"knowledge": 5, "legitimacy": 3}},
    ]),
    ("Mass Baptism", "Thousands wish to be baptized into your faith at once.", [
        {"text": "Welcome them all", "effects": {"spread_rate": 8, "authority": 3}},
        {"text": "Require education first", "effects": {"education_all": 3, "knowledge": 5}},
    ]),
    ("Heretical Book", "A book criticizing your faith becomes wildly popular.", [
        {"text": "Ban and burn it", "effects": {"authority": 5, "knowledge": -3, "stability_all": -2}},
        {"text": "Write a rebuttal", "effects": {"knowledge": 8, "legitimacy": 5}},
        {"text": "Ignore it", "effects": {"tolerance": 3}},
    ]),
    ("Peace Conference", "Multiple kingdoms propose a peace conference, seeking your faith's moral authority to broker it.", [
        {"text": "Host the conference", "effects": {"gold": -50, "legitimacy": 15, "authority": 5}},
        {"text": "Decline — stay neutral", "effects": {"tolerance": 3}},
    ]),
    ("Volcanic Eruption", "A distant volcano erupts, sending ash clouds across the sky. People are terrified.", [
        {"text": "Comfort the frightened", "effects": {"charity": 8, "legitimacy": 5}},
        {"text": "Interpret as divine anger", "effects": {"authority": 8, "ritual": 5}},
    ]),
]

# Add all standalone events
all_standalone = faith_events + political_events + war_events + economy_events + \
                 culture_events + disaster_events + internal_events + misc_events

for title, desc, choices in all_standalone:
    min_turn = random.randint(1, 30)
    weight = random.randint(5, 15)
    cooldown = random.randint(3, 10)
    conditions = {"min_turn": min_turn}
    if random.random() < 0.3:
        conditions["min_faith_spread"] = random.randint(5, 30)
    if random.random() < 0.2:
        conditions["min_authority"] = random.randint(10, 40)
    make_event(title, desc, choices, conditions, weight, cooldown)

# Generate more procedural events to reach 200+
adjectives = ["Divine", "Sacred", "Holy", "Blessed", "Eternal", "Ancient", "Mystic", "Celestial", "Radiant", "Hallowed"]
nouns = ["Oracle", "Vision", "Prophecy", "Omen", "Miracle", "Revelation", "Blessing", "Judgment", "Storm", "Dawn"]
actions_pos = ["spreads joy", "inspires the faithful", "strengthens belief", "unites the people", "brings hope"]
actions_neg = ["causes doubt", "tests the faithful", "divides opinion", "threatens stability", "challenges authority"]

while len(events) < 220:
    adj = random.choice(adjectives)
    noun = random.choice(nouns)
    title = f"The {adj} {noun}"

    if random.random() < 0.5:
        action = random.choice(actions_pos)
        desc = f"A {adj.lower()} {noun.lower()} {action} across the land. Your response will shape the faith's future."
        choices = [
            {"text": "Embrace it fully", "effects": {
                random.choice(["authority", "legitimacy", "spread_rate"]): random.randint(3, 10),
                random.choice(["ritual", "knowledge", "charity"]): random.randint(2, 8)
            }},
            {"text": "Proceed with caution", "effects": {
                random.choice(["tolerance", "knowledge"]): random.randint(3, 8)
            }},
            {"text": "Reject it", "effects": {
                random.choice(["authority", "militarism"]): random.randint(2, 5),
                random.choice(["tolerance", "spread_rate"]): random.randint(-5, -2)
            }},
        ]
    else:
        action = random.choice(actions_neg)
        desc = f"A {adj.lower()} {noun.lower()} {action}. The faithful look to you for guidance."
        choices = [
            {"text": "Stand firm", "effects": {
                random.choice(["authority", "militarism"]): random.randint(3, 8)
            }},
            {"text": "Adapt and overcome", "effects": {
                random.choice(["tolerance", "knowledge", "commerce"]): random.randint(3, 10)
            }},
            {"text": "Seek compromise", "effects": {
                "legitimacy": random.randint(2, 6),
                "stability_all": random.randint(1, 3)
            }},
        ]

    min_turn = random.randint(1, 40)
    weight = random.randint(5, 12)
    cooldown = random.randint(4, 8)
    make_event(title, desc, choices, {"min_turn": min_turn}, weight, cooldown)

# Output
output = {"events": events}
output_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           "Resources", "Events", "events_pack.json")
os.makedirs(os.path.dirname(output_path), exist_ok=True)

with open(output_path, "w") as f:
    json.dump(output, f, indent=2)

print(f"Generated {len(events)} events")
print(f"Chain events (weight=0): {sum(1 for e in events if e.get('weight', 10) == 0)}")
print(f"Standalone events: {sum(1 for e in events if e.get('weight', 10) > 0)}")
print(f"Output: {output_path}")

import requests
from bs4 import BeautifulSoup
import re

# Current Season Dungeons (TWW S1)
CURRENT_SEASON = [
    {"name": "The Stonevault", "url": "https://www.icy-veins.com/wow/the-stonevault-dungeon-guide"},
    {"name": "The Dawnbreaker", "url": "https://www.icy-veins.com/wow/the-dawnbreaker-dungeon-guide"},
    {"name": "Mists of Tirna Scithe", "url": "https://www.icy-veins.com/wow/mists-of-tirna-scithe-dungeon-guide"},
    {"name": "Siege of Boralus", "url": "https://www.icy-veins.com/wow/siege-of-boralus-dungeon-guide"},
    {"name": "Grim Batol", "url": "https://www.icy-veins.com/wow/grim-batol-dungeon-guide"},
    {"name": "City of Threads", "url": "https://www.icy-veins.com/wow/city-of-threads-dungeon-guide"},
    {"name": "Ara-Kara, City of Echoes", "url": "https://www.icy-veins.com/wow/ara-kara-city-of-echoes-dungeon-guide"},
    {"name": "Cinderbrew Meadery", "url": "https://www.icy-veins.com/wow/cinderbrew-meadery-dungeon-guide"},
]

# Timewalking & Other Dungeons
TIMEWALKING = [
    # Burning Crusade
    {"name": "The Arcatraz", "url": "https://www.icy-veins.com/wow/the-arcatraz-dungeon-guide"},
    {"name": "Black Morass", "url": "https://www.icy-veins.com/wow/black-morass-dungeon-guide"},
    {"name": "The Mechanar", "url": "https://www.icy-veins.com/wow/the-mechanar-dungeon-guide"},
    
    # Wrath
    {"name": "Halls of Lightning", "url": "https://www.icy-veins.com/wow/halls-of-lightning-dungeon-guide"},
    {"name": "Pit of Saron", "url": "https://www.icy-veins.com/wow/pit-of-saron-dungeon-guide"},
    
    # Cataclysm
    {"name": "End Time", "url": "https://www.icy-veins.com/wow/end-time-dungeon-guide"},
    {"name": "Well of Eternity", "url": "https://www.icy-veins.com/wow/well-of-eternity-dungeon-guide"},
    
    # MoP
    {"name": "Gate of the Setting Sun", "url": "https://www.icy-veins.com/wow/gate-of-the-setting-sun-dungeon-guide"},
    {"name": "Siege of Niuzao Temple", "url": "https://www.icy-veins.com/wow/siege-of-niuzao-temple-dungeon-guide"},
    
    # WoD
    {"name": "Iron Docks", "url": "https://www.icy-veins.com/wow/iron-docks-dungeon-guide"},
    {"name": "Grimrail Depot", "url": "https://www.icy-veins.com/wow/grimrail-depot-dungeon-guide"},
    
    # Legion
    {"name": "Court of Stars", "url": "https://www.icy-veins.com/wow/court-of-stars-dungeon-guide"},
    {"name": "Black Rook Hold", "url": "https://www.icy-veins.com/wow/black-rook-hold-dungeon-guide"},
]

DUNGEONS = CURRENT_SEASON + TIMEWALKING

# Current Raid (TWW S1)
RAIDS = [
    {"name": "Nerub-ar Palace", "url": "https://www.icy-veins.com/wow/nerubar-palace-raid-guide"},
]

OUTPUT_FILE = "db/Interrupts.lua"

def fetch_page(url):
    print(f"Fetching {url}...")
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 404:
            print(f"  404 Not Found")
            return None
        response.raise_for_status()
        return response.text
    except Exception as e:
        print(f"  Error: {e}")
        return None

def parse_interrupts(html, content_name):
    if not html:
        return {}
    
    soup = BeautifulSoup(html, 'html.parser')
    interrupts = {}
    
    # Strategy: Look for sections with "Interrupt", "Dispel", "Important"
    # Common patterns:
    # - "Important Interrupts"
    # - "Abilities to Interrupt"
    # - Boss/Trash sections with spell lists
    
    # Find all headings and their following lists
    headings = soup.find_all(['h2', 'h3', 'h4'])
    
    for heading in headings:
        heading_text = heading.get_text().lower()
        
        # Check if this is an interrupt-related section
        if any(word in heading_text for word in ['interrupt', 'kick', 'stop', 'priority']):
            # Find the next list (ul or ol)
            next_list = heading.find_next(['ul', 'ol'])
            if next_list:
                # Extract spell names
                items = next_list.find_all('li')
                for item in items:
                    text = item.get_text().strip()
                    # Look for spell-like text (capitalized words)
                    # Common patterns: "Spell Name - description"
                    match = re.search(r'^([A-Z][A-Za-z\s\']+?)(?:\s*-|\s*:|\s*\()', text)
                    if match:
                        spell = match.group(1).strip()
                        # Categorize as priority (default) or optional
                        is_priority = 'must' in heading_text or 'priority' in heading_text or 'important' in heading_text
                        
                        # Use heading as mob/boss name if available
                        mob_name = content_name
                        parent_heading = heading.find_previous(['h2', 'h3'])
                        if parent_heading:
                            mob_name = parent_heading.get_text().strip()
                        
                        if mob_name not in interrupts:
                            interrupts[mob_name] = {'priority': [], 'optional': []}
                        
                        if is_priority:
                            interrupts[mob_name]['priority'].append(spell)
                        else:
                            interrupts[mob_name]['optional'].append(spell)
    
    return interrupts

def generate_lua(dungeons, raids):
    lua_content = """local ADDON_NAME, SkillWeaver = ...
-- GENERATED FILE - DO NOT EDIT MANUALLY
-- Scraped from Icy Veins Dungeon/Raid Guides

SkillWeaver.Interrupts = SkillWeaver.Interrupts or {}

"""
    
    # Process Dungeons
    lua_content += "-- Mythic+ Dungeons\n"
    for dungeon in dungeons:
        html = fetch_page(dungeon['url'])
        data = parse_interrupts(html, dungeon['name'])
        
        if data:
            print(f"  Found {len(data)} interrupt targets")
            lua_content += f'SkillWeaver.Interrupts["{dungeon["name"]}"] = {{\n'
            
            for mob, spells in data.items():
                if spells['priority'] or spells['optional']:
                    lua_content += f'    ["{mob}"] = {{\n'
                    
                    if spells['priority']:
                        lua_content += '        priority = {'
                        lua_content += ', '.join([f'"{s}"' for s in spells['priority']])
                        lua_content += '},\n'
                    
                    if spells['optional']:
                        lua_content += '        optional = {'
                        lua_content += ', '.join([f'"{s}"' for s in spells['optional']])
                        lua_content += '},\n'
                    
                    lua_content += '    },\n'
            
            lua_content += '}\n\n'
        else:
            print(f"  No interrupts found")
    
    # Process Raids
    lua_content += "-- Raids\n"
    for raid in raids:
        html = fetch_page(raid['url'])
        data = parse_interrupts(html, raid['name'])
        
        if data:
            print(f"  Found {len(data)} interrupt targets")
            lua_content += f'SkillWeaver.Interrupts["{raid["name"]}"] = {{\n'
            
            for boss, spells in data.items():
                if spells['priority'] or spells['optional']:
                    lua_content += f'    ["{boss}"] = {{\n'
                    
                    if spells['priority']:
                        lua_content += '        priority = {'
                        lua_content += ', '.join([f'"{s}"' for s in spells['priority']])
                        lua_content += '},\n'
                    
                    if spells['optional']:
                        lua_content += '        optional = {'
                        lua_content += ', '.join([f'"{s}"' for s in spells['optional']])
                        lua_content += '},\n'
                    
                    lua_content += '    },\n'
            
            lua_content += '}\n\n'
        else:
            print(f"  No interrupts found")
    
    with open(OUTPUT_FILE, "w") as f:
        f.write(lua_content)
    print(f"\nGenerated {OUTPUT_FILE}")

if __name__ == "__main__":
    print("=== Scraping Dungeon Guides ===")
    generate_lua(DUNGEONS, RAIDS)

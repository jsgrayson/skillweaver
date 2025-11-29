import mss
import numpy as np
import json
import time
import os
import sys
import threading
from pynput import keyboard
from pynput.keyboard import Key, Controller

# --- CONFIGURATION ---
CONFIG_FILE = "visual_config.json"
DEFAULT_CONFIG = {
    "trigger_key": "space",
    "healer_mode": False,
    "regions": {
        "dps_icon": {"top": 500, "left": 500, "width": 20, "height": 20},
        "party1": {"top": 200, "left": 100, "width": 100, "height": 30},
        "party2": {"top": 240, "left": 100, "width": 100, "height": 30},
        "party3": {"top": 280, "left": 100, "width": 100, "height": 30},
        "party4": {"top": 320, "left": 100, "width": 100, "height": 30},
        "party5": {"top": 360, "left": 100, "width": 100, "height": 30}
    },
    "key_map": {
        # Blue Channel -> Key
        20: "1", 40: "2", 60: "3", 80: "4", 
        100: "5", 120: "6", 140: "7", 160: "8", 
        180: "9", 200: "0", 220: "-", 240: "="
    },
    "mod_map": {
        # Green Channel -> Modifier
        0: None,
        64: Key.shift,
        128: Key.ctrl,
        192: Key.alt
    },
    "special_keys": {
        "interrupt": "r",
        "cycle": "tab",
        "trinket": "t",
        "pet_action": "a" # Key to spam for Pet Battles
    },
    "tolerance": 15
}

class VisualWeaver:
    def __init__(self):
        self.config = DEFAULT_CONFIG
        self.paused = True
        self.healer_mode = False
        self.pet_mode = False
        self.running = False
        self.trigger_pressed = False
        self.keyboard_controller = Controller()
        self.thread = None
        self.load_config()

    def load_config(self):
        """Loads configuration from visual_config.json or creates a default one."""
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, 'r') as f:
                self.config = json.load(f)
            print(f"Configuration loaded from {CONFIG_FILE}")
        else:
            self.config = DEFAULT_CONFIG
            with open(CONFIG_FILE, 'w') as f:
                json.dump(self.config, f, indent=4)
            print(f"Default configuration created at {CONFIG_FILE}")

    def save_config(self):
        with open(CONFIG_FILE, 'w') as f:
            json.dump(self.config, f, indent=4)
        print("Configuration saved.")

    def on_press(self, key):
        try:
            # Control Keys
            if key == Key.f8:
                self.paused = not self.paused
                print(f"[{'PAUSED' if self.paused else 'RESUMED'}]")
            elif key == Key.f9:
                self.healer_mode = not self.healer_mode
                self.pet_mode = False # Exclusive
                print(f"Healer Mode: {'ON' if self.healer_mode else 'OFF'}")
            elif key == Key.f11:
                self.pet_mode = not self.pet_mode
                self.healer_mode = False # Exclusive
                print(f"Pet Battle Mode: {'ON' if self.pet_mode else 'OFF'}")
            elif key == keyboard.KeyCode.from_char('q'):
                print("Quitting...")
                self.stop()
            
            # Trigger Key
            if str(key).replace("'", "") == self.config["trigger_key"]:
                self.trigger_pressed = True
                
        except AttributeError:
            if str(key).replace("'", "") == self.config["trigger_key"]:
                self.trigger_pressed = True

    def on_release(self, key):
        if str(key).replace("'", "") == self.config["trigger_key"]:
            self.trigger_pressed = False

    def get_action_from_color(self, r, g, b):
        """Decodes the pixel color into an action (Key + Modifier)."""
        tolerance = self.config["tolerance"]
        
        # 1. Check Interrupt (Red)
        if r > 200 and g < 50 and b < 50:
            return self.config["special_keys"]["interrupt"], None
            
        # 2. Check Trinket (Magenta: Red + Blue)
        if r > 200 and g < 50 and b > 200:
            return self.config["special_keys"].get("trinket", "t"), None

        # 3. Check Cycle (Cyan: Green + Blue)
        if r < 50 and g > 200 and b > 200:
            return self.config["special_keys"]["cycle"], None
            
        # 3. Check Rotation (Blue + Green Mod)
        # Find closest Key (Blue)
        best_key = None
        min_dist = float('inf')
        
        for val, key in self.config["key_map"].items():
            dist = abs(int(val) - b)
            if dist < min_dist:
                min_dist = dist
                best_key = key
                
        if min_dist > tolerance:
            return None, None # No key detected
            
        # Find closest Modifier (Green)
        best_mod = None
        min_mod_dist = float('inf')
        
        for val, mod in self.config["mod_map"].items():
            dist = abs(int(val) - g)
            if dist < min_mod_dist:
                min_mod_dist = dist
                best_mod = mod
                
        return best_key, best_mod

    def run_loop(self):
        print("Visual Weaver Loop Started 👁️")
        with mss.mss() as sct:
            while self.running:
                if not self.paused and self.trigger_pressed:
                    region = self.config["regions"]["dps_icon"]
                    monitor = {
                        "top": int(region["top"]), 
                        "left": int(region["left"]), 
                        "width": int(region["width"]), 
                        "height": int(region["height"])
                    }
                    
                    img = np.array(sct.grab(monitor))
                    cy, cx = region["height"] // 2, region["width"] // 2
                    pixel = img[cy, cx]
                    b, g, r = int(pixel[0]), int(pixel[1]), int(pixel[2])
                    
                    key_to_press, modifier = self.get_action_from_color(r, g, b)
                    
                    if key_to_press:
                        mod_str = f"{modifier}+" if modifier else ""
                        print(f"Color ({r},{g},{b}) -> {mod_str}{key_to_press}")
                        
                        if modifier:
                            self.keyboard_controller.press(modifier)
                            time.sleep(0.01)
                            
                        self.keyboard_controller.press(key_to_press)
                        time.sleep(0.05 + np.random.uniform(0.01, 0.03))
                        self.keyboard_controller.release(key_to_press)
                        
                        if modifier:
                            self.keyboard_controller.release(modifier)
                            
                        time.sleep(0.1)
                    
                # 3. Pet Battle Mode (Auto-Script)
                if not self.paused and self.pet_mode:
                    pet_key = self.config["special_keys"].get("pet_action", "a")
                    print(f"Pet Mode: Pressing {pet_key}")
                    self.keyboard_controller.press(pet_key)
                    time.sleep(0.05)
                    self.keyboard_controller.release(pet_key)
                    time.sleep(0.5) # Spam rate
                
                time.sleep(0.01) # Loop rate
        print("Visual Weaver Loop Stopped.")

    def start(self):
        if self.running:
            return
        self.running = True
        self.listener = keyboard.Listener(on_press=self.on_press, on_release=self.on_release)
        self.listener.start()
        
        self.thread = threading.Thread(target=self.run_loop)
        self.thread.start()

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join()
        if hasattr(self, 'listener'):
            self.listener.stop()

if __name__ == "__main__":
    weaver = VisualWeaver()
    weaver.start()
    print("Press F8 to Pause/Resume. Press Q to Quit.")
    try:
        while weaver.running:
            time.sleep(1)
    except KeyboardInterrupt:
        weaver.stop()

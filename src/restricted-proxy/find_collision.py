from web3 import Web3
import string
import random

def get_selector(func_sig):
    """Get first 4 bytes of keccak256 hash of the function signature"""
    return Web3.keccak(text=func_sig)[:4]

def random_string(length):
    """Generate random string of given length"""
    chars = string.ascii_letters + string.digits + '_'
    return ''.join(random.choice(chars) for _ in range(length))

target_selector = get_selector("changeWithdrawRate(uint8)")
print(f"Target selector: 0x{target_selector.hex()}")

# Try random strings until we find a collision
count = 0
while True:
    count += 1
    if count % 1000000 == 0:
        print(f"Tried {count} combinations...")
    
    # Generate random function name
    name = random_string(random.randint(1, 20))
    func_sig = f"{name}(uint256)"
    
    selector = get_selector(func_sig)
    if selector == target_selector:
        print(f"\nFound collision!")
        print(f"Original: changeWithdrawRate(uint8)")
        print(f"Colliding: {func_sig}")
        print(f"Selector: 0x{selector.hex()}")
        break

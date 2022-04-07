from distutils.log import error
from multiprocessing import pool
from multiprocessing.dummy import Array
import os
from operator import itemgetter
from tokenize import String
from typing import Any
from dotenv import dotenv_values
from time import time
from algosdk import mnemonic
from algofi_amm.v0.asset import Asset
from algofi_amm.v0.pool import Pool
from algofi_amm.v0.client import AlgofiAMMMainnetClient
from algofi_amm.v0.config import PoolType, PoolStatus
from algofi_amm.utils import TransactionGroup
from tinyman.v1.client import TinymanMainnetClient

my_path = os.path.abspath(os.path.dirname(__file__))
ENV_PATH = os.path.join(my_path, ".env")
user = dotenv_values(ENV_PATH)
my_address = mnemonic.to_public_key(user['mnemonic'])
my_key =  mnemonic.to_private_key(user['mnemonic'])

FEE = 0.0025
asset_ids = {
    'GOBTC': 386192725,
    'GOETH': 386195940,
    'ALGO': 1,
    'STBL': 465865291,
    'USDC': 31566704,
    'GOMINT': 441139422,
    'USDT': 312769,
    'YLDY': 226701642,
    'OPUL': 287867876,
    'DEFLY': 470842789,
    'STKE': 511484048,
    'GEMS': 230946361,
    'PLANETS': 27165954
}

tinyman_supported_pools = [
    ('USDC', 'ALGO'),
    ('YLDY', 'ALGO'),
    ('GOMINT', 'ALGO'),
    ('PLANETS', 'ALGO'),
    ('OPUL', 'ALGO'),
    ('STBL', 'USDC'),
    ('USDC', 'USDT'),
    ('GEMS', 'ALGO'),
    ('DEFLY', 'ALGO'),
    ('STKE', 'ALGO'),
    ('GOBTC', 'ALGO'),
    ('GOETH', 'ALGO'),
    ('OPUL', 'USDC'),
    ('STBL', 'ALGO'),
    ('USDT', 'ALGO')
]

algofi_supported_pools = [
    ('ALGO', 'STBL', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('ALGO', 'USDC', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('ALGO', 'GOMINT', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('ALGO', 'DEFLY', PoolType.CONSTANT_PRODUCT_75BP_FEE),
    ('USDC', 'STBL', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('GOBTC', 'STBL', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('GOETH', 'STBL', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('OPUL', 'STBL', PoolType.CONSTANT_PRODUCT_75BP_FEE),
    ('ALGO', 'OPUL', PoolType.CONSTANT_PRODUCT_75BP_FEE),
    ('ALGO', 'GOETH', PoolType.CONSTANT_PRODUCT_25BP_FEE)
]

def main():
    """main function
    """
    
    print(f"My key is {my_key} and my address is {my_address}")
    print(f"Supported assets are {asset_ids}")
    
    start_time = time()
    # algofi_prices = get_prices_algofi()
    tinyman_prices = get_prices_tinyman()
    end_time = time()
    print(f"Downloaded prices in {end_time - start_time}")
    print(f"Prices {tinyman_prices}")

    start_time = time()
    triangles = list(find_triangles(tinyman_prices))
    end_time = time()

    print(f"Computed triangles in {end_time - start_time}")
    if triangles:
        for triangle in sorted(triangles, key=itemgetter('profit'), reverse=True):
            describe_triangle(tinyman_prices, triangle)
            # arbitrage(triangle=triangle)
    else:
        print("No triangles found, try again!")

def arbitrage(triangle: dict[str: Any]):
    """price method
    :param pools: a list of :class:`PoolType` objects
    :type pools: :class:`PoolType`
    """

    client = AlgofiAMMMainnetClient(user_address=my_address)

    coins = triangle['coins']

    transactions = TransactionGroup([])
    for i in range(len(coins) - 1):
        asset1_key = coins[i]
        asset1_id = asset_ids[asset1_key]
        asset2_key = coins[i + 1]
        asset2_id = asset_ids[asset2_key]
        pool = client.get_pool(PoolType.CONSTANT_PRODUCT_25BP_FEE, asset1_id=asset1_id, asset2_id=asset2_id)    


def find_triangles(prices: dict[str: dict[str: float]]):
    """price method
    :param pools: a list of :class:`PoolType` objects
    :type pools: :class:`PoolType`
    """
    triangles = []
    for starting_coin in asset_ids.keys():
        for triangle in recurse_triangle(prices, starting_coin, starting_coin):
            coins = set(triangle['coins'])
            if not any(prev_triangle == coins for prev_triangle in triangles):
                yield triangle
                triangles.append(coins)
    
def recurse_triangle(prices: dict[str: dict[str: float]], current_coin: str, starting_coin: str, depth_left: int = 3, amount: float = 1.0):
    """price method
    :param pools: a list of :class:`PoolType` objects
    :type pools: :class:`PoolType`
    """
    if depth_left > 0:
        if current_coin in prices:
            pairs = prices[current_coin]
            for coin, price in pairs.items():
                new_price = (amount * price) * (1.0 - FEE)
                for triangle in recurse_triangle(prices, coin, starting_coin, depth_left - 1, new_price):
                    triangle['coins'] = triangle['coins'] + [current_coin]
                    yield triangle
    elif current_coin == starting_coin and amount > 1.0:
        yield {
            'coins': [current_coin],
            'profit': amount
        }

def describe_triangle(prices, triangle):
    """price method
    """
    coins = triangle['coins']
    price_percentage = (triangle['profit'] - 1.0) * 100
    print(f"{'->'.join(coins):26} {round(price_percentage, 4):-7}% <- profit!")
    for i in range(len(coins) - 1):
        first = coins[i]
        second = coins[i + 1]
        print(f"     {second:4} / {first:4}: {prices[first][second]:-17.8f}")
    print('')

def get_prices_algofi():
    """price method
    """
    client = AlgofiAMMMainnetClient(user_address=my_address)
    prices = {}
    for asset1_key, asset2_key, pool_type in algofi_supported_pools:
        asset1_id = asset_ids[asset1_key]
        asset2_id = asset_ids[asset2_key]
        try:
            pool = client.get_pool(pool_type=pool_type, asset1_id=asset1_id, asset2_id=asset2_id)
            pool.refresh_state()
            if asset1_key not in prices:
                prices[asset1_key] = {}
            prices[asset1_key][asset2_key] = pool.get_pool_price(asset_id=asset1_id)
            if asset2_key not in prices:
                prices[asset2_key] = {}
            prices[asset2_key][asset1_key] = pool.get_pool_price(asset_id=asset2_id)
        except Exception as error:
            print(f"Failed to add pool. error={error}, asset1={asset1_key}, asset2={asset2_key}")
            continue

    return prices

def get_prices_tinyman():
    """price method
    """
    client = TinymanMainnetClient(user_address=my_address)
    prices = {}

    for asset1_key, asset2_key in tinyman_supported_pools:
        asset1_id = asset_ids[asset1_key]
        asset2_id = asset_ids[asset2_key]

        if asset2_id == 1:
            asset2_id = 0

        try:
            pool = client.fetch_pool(asset1=asset1_id, asset2=asset2_id)
            if asset1_key not in prices:
                prices[asset1_key] = {}
            prices[asset1_key][asset2_key] = pool.asset1_price
            if asset2_key not in prices:
                prices[asset2_key] = {}
            prices[asset2_key][asset1_key] = pool.asset2_price
        except Exception as error:
            print(f"Failed to add pool. error={error}, asset1={asset1_key}, asset2={asset2_key}")
            continue

    return prices

if __name__ == '__main__':    
    main()
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
from enum import Enum, unique

from algofi_amm.v0.asset import Asset
from algofi_amm.v0.pool import Pool
from algofi_amm.v0.client import AlgofiAMMMainnetClient
from algofi_amm.v0.config import PoolType
from algofi_amm.utils import TransactionGroup
from tinyman.v1.client import TinymanMainnetClient
from algosdk.v2client.algod import AlgodClient
import pactsdk

my_path = os.path.abspath(os.path.dirname(__file__))
ENV_PATH = os.path.join(my_path, ".env")
user = dotenv_values(ENV_PATH)
my_address = mnemonic.to_public_key(user['mnemonic'])
my_key =  mnemonic.to_private_key(user['mnemonic'])

asset_ids = {
    'GOBTC': 386192725,
    'GOETH': 386195940,
    'ALGO': 0,
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
    ('USDT', 'ALGO'),
    ('OPUL', 'USDC')
]

algofi_supported_pools = [
    ('ALGO', 'STBL', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('ALGO', 'USDC', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('ALGO', 'GOMINT', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('ALGO', 'DEFLY', PoolType.CONSTANT_PRODUCT_75BP_FEE),
    ('USDC', 'STBL', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    # ('USDC', 'STBL', PoolType.NANOSWAP),
    ('GOBTC', 'STBL', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('GOETH', 'STBL', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('OPUL', 'STBL', PoolType.CONSTANT_PRODUCT_75BP_FEE),
    ('ALGO', 'OPUL', PoolType.CONSTANT_PRODUCT_75BP_FEE),
    ('ALGO', 'GOETH', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('STBL', 'DEFLY', PoolType.CONSTANT_PRODUCT_75BP_FEE),
    ('ALGO', 'GOBTC', PoolType.CONSTANT_PRODUCT_25BP_FEE),
    ('ALGO', 'GOETH', PoolType.CONSTANT_PRODUCT_25BP_FEE),
]

pact_supported_pools = [
    ('USDT', 'USDC'),
    ('ALGO', 'GOBTC'),
    ('ALGO', 'USDC'),
    ('ALGO', 'GOETH'),
    ('ALGO', 'GOMINT'),
    ('ALGO', 'DEFLY'),
    ('ALGO', 'OPUL'),
    ('USDC', 'OPUL')
]

@unique
class Exchange(Enum):
    ALGOFI = 1
    TINYMAN = 2
    PACT = 3

class ExchangeRate:
    def __init__(self, price: float, exchange: Exchange, fee: float):
        self.price = price
        self.fee = fee
        self.exchange = exchange

    def __repr__(self): 
        return "{ " + str(self.price) + ", " + str(self.exchange) +  ", " + str(self.fee) + " }"

def main():
    """main function
    """
    
    print(f"My key is {my_key} and my address is {my_address}")
    
    start_time = time()
    algofi_prices = get_prices_algofi()
    tinyman_prices = get_prices_tinyman()
    pact_prices = get_prices_pact()
    end_time = time()
    print(f"Downloaded prices in {end_time - start_time}")
    
    start_time = time()
    exchange_rates = create_exchange_rates([algofi_prices, tinyman_prices, pact_prices])
    end_time = time()
    print(f"Created exchange rates in {end_time - start_time}")
    print(f'Exchange Rates = {exchange_rates}')

    start_time = time()
    triangles = list(find_triangles(exchange_rates))
    end_time = time()

    print(f"Computed triangles in {end_time - start_time}")
    if triangles:
        for triangle in sorted(triangles, key=itemgetter('profit'), reverse=True):
            describe_triangle(exchange_rates, triangle)
            # arbitrage(triangle=triangle)
    else:
        print("No triangles found, try again!")

def create_exchange_rates(exchange_rates: list[dict[str: dict[str: ExchangeRate]]]):
    """price method
    :param pools: a list of :class:`PoolType` objects
    :type pools: :class:`PoolType`
    """

    results: dict[str: dict[str: ExchangeRate]] = {}
    for dictionary in exchange_rates:
        for coin1, pairs in dictionary.items():
            if coin1 not in results:
                    results[coin1] = {}
            for coin2, exchange_rate in pairs.items():
                if coin2 not in results[coin1]:
                    results[coin1][coin2] = exchange_rate
                    continue

                current_exchange_rate = results[coin1][coin2]
                if current_exchange_rate.price < exchange_rate.price:
                    results[coin1][coin2] = exchange_rate
                elif current_exchange_rate.price == exchange_rate.price and current_exchange_rate.fee > exchange_rate.fee:
                    results[coin1][coin2] = exchange_rate

    return results

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


def find_triangles(prices: dict[str: dict[str: ExchangeRate]]):
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
    
def recurse_triangle(prices: dict[str: dict[str: ExchangeRate]], current_coin: str, starting_coin: str, depth_left: int = 3, amount: float = 1.0):
    """price method
    :param pools: a list of :class:`PoolType` objects
    :type pools: :class:`PoolType`
    """
    if depth_left > 0:
        if current_coin in prices:
            pairs = prices[current_coin]
            for coin, exchange_rate in pairs.items():
                new_price = (amount * exchange_rate.price) * (1.0 - exchange_rate.fee)
                for triangle in recurse_triangle(prices, coin, starting_coin, depth_left - 1, new_price):
                    triangle['coins'] = triangle['coins'] + [current_coin]
                    yield triangle
    elif current_coin == starting_coin and amount > 1.0:
        yield {
            'coins': [current_coin],
            'profit': amount,
        }

def describe_triangle(prices: dict[str: dict[str: ExchangeRate]], triangle):
    """price method
    """
    coins = triangle['coins']
    price_percentage = (triangle['profit'] - 1.0) * 100
    print(f"{'->'.join(coins):26} {round(price_percentage, 4):-7}% <- profit!")
    for i in range(len(coins) - 1):
        first = coins[i]
        second = coins[i + 1]
        print(f"     {second:4} / {first:4}: {prices[first][second].price:-17.8f} {prices[first][second].exchange}")
    print('')

def get_prices_algofi():
    """price method
    """
    client = AlgofiAMMMainnetClient(user_address=my_address)
    prices = {}
    for asset1_key, asset2_key, pool_type in algofi_supported_pools:
        asset1_id = asset_ids[asset1_key]
        asset2_id = asset_ids[asset2_key]

        if asset1_id == 0:
            asset1_id = 1
        if asset2_id == 0:
            asset2_id = 1

        try:
            pool = client.get_pool(pool_type=pool_type, asset1_id=asset1_id, asset2_id=asset2_id)
            pool.refresh_state()

            if asset1_key not in prices:
                prices[asset1_key] = {}
            prices[asset1_key][asset2_key] = ExchangeRate(
                pool.get_pool_price(asset_id=asset1_id), 
                Exchange.ALGOFI, 
                pool.swap_fee
            )

            if asset2_key not in prices:
                prices[asset2_key] = {}
            prices[asset2_key][asset1_key] = ExchangeRate(
                pool.get_pool_price(asset_id=asset2_id), 
                Exchange.ALGOFI, 
                pool.swap_fee
            )
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

        try:
            pool = client.fetch_pool(asset1=asset1_id, asset2=asset2_id)
            if asset1_key not in prices:
                prices[asset1_key] = {}
            prices[asset1_key][asset2_key] = ExchangeRate(pool.asset1_price, Exchange.TINYMAN, 0.003)

            if asset2_key not in prices:
                prices[asset2_key] = {}
            prices[asset2_key][asset1_key] = ExchangeRate(pool.asset2_price, Exchange.TINYMAN, 0.003)
        except Exception as error:
            print(f"Failed to add pool. error={error}, asset1={asset1_key}, asset2={asset2_key}")
            continue

    return prices

def get_prices_pact():
    """price method
    """
    algod = AlgodClient('', 'https://api.algoexplorer.io', headers={'User-Agent': 'algosdk'})
    client = pactsdk.PactClient(algod)

    prices = {}
    for asset1_key, asset2_key in tinyman_supported_pools:
        asset1_id = asset_ids[asset1_key]
        asset2_id = asset_ids[asset2_key]

        try:
            pool = client.fetch_pools_by_assets(primary_asset=asset1_id, secondary_asset=asset2_id)[0]
            if asset1_key not in prices:
                prices[asset1_key] = {}
            primary_asset_price = float(pool.calculator.secondary_asset_price)
            prices[asset1_key][asset2_key] = ExchangeRate(primary_asset_price, Exchange.PACT, pool.fee_bps / 10000)

            if asset2_key not in prices:
                prices[asset2_key] = {}
            secondary_asset_price = float(pool.calculator.primary_asset_price)
            prices[asset2_key][asset1_key] = ExchangeRate(secondary_asset_price, Exchange.PACT, pool.fee_bps / 10000)
                
        except Exception as error:
            print(f"Failed to add pool. error={error}, asset1={asset1_key}, asset2={asset2_key}")
            continue

    return prices



if __name__ == '__main__':    
    main()
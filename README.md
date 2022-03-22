# Install
- Follow the instructions to install [eth-brownie](https://github.com/eth-brownie/brownie).
- Copy `.env.example` -> `.env` and populate the keys.

# Run
```
brownie compile
brownie run scripts/test_deploy.py
```

# Citadel (CTDL) Token:
The base token of the system, an upgradeable ERC20 token that is minted according to the supply schedule.

# xCitadel Vault:
A staked CTDL position that increases in value automatically as emission rewards are distributed by the project.

The code is a fork of badger vaults 1.5 with no strategy which allows users to deposit CTDL token and receive xCTDL token. 

Each xCTDL is worth a certain amount of CTDL using the pricePerShare() mechanic.
CTDL is "auto-compounded" into the vault to increase the value of each xCTDL token.

Withdrawing from the vault has a 21 day exit vesting period.

## Vested Exit
Upon withdraw from xCitadel vault CTDL tokens are sent to vesting contract wherein they are vested linearly for 21 days. Users are welcome to partially withdraw vested balances as desired.

Each user can only have one vested exit active at a time. A second withdrawal during that vesting timeframe resets the timer to 21 days.

# xCitadelLocker:
Allows locking of xCTDL token for 21 weeks based upon the [convex locker](https://github.com/convex-eth/platform/blob/main/contracts/contracts/CvxLocker.sol) model.

Some resources on locking:
- [Primer on convex locking](https://docs.convexfinance.com/convexfinance/general-information/voting-and-gauge-weights/vote-locking)
- [Convex locking UI](https://www.convexfinance.com/lock-cvx)

Locking allows users to earn governance rights and claimable xCTDL rewards.

<strong> Modifications made to convex locker: </strong>
- locker made upgradeable
- staking contract is disabled so all the xCTDL token would remain in the locker
- addRewards modified to allow distribution of staking token too
- `kickRewardPerEpoch` removed from function `_processExpiredLocks` to disable giving of kick rewards

# CTDL Token Distribution:
The _SupplySchedule_ contract defines the rate at which CTDL minting can occur. It is set by epoch by policy governance.

Minting process originiates via a call to the _CTDLMinter_. It's distributed between funding pools, stakers, and lockers according to logic which is in the works.

In the live system, policy governance will call `CTDLMinter.mintAndDistribute(treasury, marketcap, % CTDL staked, % CTDL locked)`

Temporarily, this function takes in the amounts to mint directly until that logic is ironed out:
`CTDLMinter.mintAndDistribute(amountToFunding, amountToStakers, amountToLockers)`

- CTDL is minted determinstically according to Epoch data and an update can happen at any time from the policy governance. This means the desired interval between mint updates can be modulated seamlessly.

# CTDLMinter:
Some notes on the mintAndDistribute() function:
- Disallow minting if there is no epoch for some part of the time range covered since last mint
- CTDL is minted according to Epoch data. Start from last mint.
- Disallow minting if there is no epoch for some part of the time range covered since last mint

How rewards are distributed:
- CTDL for stakers is injected into xCTDL to increase ppfs
- CTDL for funding pool is deposited into xCTDL, and sent to funding pool management for use in funding 
- CTDL for lockers is deposited into xCTDL and transferred to locking contract. The rewards rate for Lockers is modified.

# Funding distribution
When CTDL is minted, a certain portion goes to the funding pool. This is distributed amongst the different asset accumulator contracts. Each contract is given a weight which determines it's proprtion of the funding pool to recieve. These weights are set by the policy team.

```
struct FundingWeight {
    mapping (address => uint) fundingWeight
    uint totalFundingWeight
}
```

> Example:
* BTC Funding Contract: 80
* CVX Funding Contract: 20

### setFundingContractWeight(address, weight) onlyPolicy
Set the funding weight for a given address. Verification on the address is simple, the address must return "funding" on the citadelContractType() call.
Funding weights must be between 1 and 10000.

### removeFundingContract(address) onlyPolicy
Remove an existing funding weight. 
The address must be in the list.
Note that a funding contract weight cannot be set to zero, so this is the only way to remove it.

# Funding Contract
Has a:
* Oracle for market price of CTDL
* Oracle for market price of the accumulated asset
* xCTDL live ppfs

From there we have the price of CTDL relative to the accumulated asset
1 asset token = x CTDL

From there we apply a *discount*.

We then deposit the CTDL into xCTDL for the user and give it to them. 
> Should we do this with all the CTDL when it comes in, diluting xCTDL holders for cheaper gas costs?

```
discount 1e18
rate 1e18
```

The discount is initially set by admin fiat.
Every time more funds enter the contract, the discount rate is modulated according to the *discount rate function*

The initial discount rate function works as follows:
* If the CTDL is sold out, decrease the discount according to *Rate*
* If the CTDL is not sold out, increase the discount according to *Rate*

Rate is set by the admin and is defined as bps / day.
Everytime the contract is funded by freshly minted citadel, we evaluate how long it has been since the last update. We then apply the rate to it.

> change = timeSinceLastUpdate * Rate


# NonFungibleFarm
Farm ERC-1155 NFT by staking ERC-20 LP Tokens

**Video Explanation:** https://youtu.be/vIcf74CvsCs

## User Flow:
 * NFT's are deposited into this contract, having some Price as `points` associated to them.
 * In order to claim an NFT, the user must have sufficient `points` to reach Price threshold.
 * To increase `points` balance, user must deposit lp tokens to this contract.
 * `points` balance increases dynamically with each passing second allowing user to Farm NFTs!

## Features:
* Supports ERC-1155 NFT
* Stake LP tokens.
* Rate of NFT accumulation proportional to amount of LP tokens user is providing.
* Farm for all NFTs at once. Choose particular NFTs on claim.
* Resume farming from where left, if LP tokens withdrawn in between.
* Claim all eligible random NFTs with farmed points balance.
* Withdraw LP tokens, and claim NFTs in single transaction.

## Functions:
```constructor(uint256 _emissionRate, IERC20 _lpToken) public```

_emissionRate: points generated per LP token (wei) per second staked by user

_lpToken: token address to be staked

```
function addNFT(
        address contractAddress,    // token contract address. Only ERC-1155 NFT Supported!
        uint256 id,                 // token id
        uint256 total,              // amount of NFTs deposited to farm (need to approve before)
        uint256 price               // price in `points`
    ) external;
```
Can only be called by owner. To add ERC-1155 NFT to be farmed by others.
Owner must have approved contract to transfer NFT before calling this function.

```
function deposit(uint256 _amount) external;
```
Called by user to stake _amount of LP tokens in the contract.
User must have approved contract to spend at least _amount of LP tokens.

```
function pointsBalance(address userAddress) public view returns (uint256) 
```
Dynamic function to get points balance accumulated till now.

```
function claim(uint256 _nftIndex, uint256 _quantity) public;
```
Allow user to claim `_quantity` of NFT at index `_nftIndex` in `nftInfo` array, if sufficient points accumulated (else transaction reverts).
NFTs are farmed and sent to user address.

```
function claimRandom() public;
```
Allow user to claim random NFTs from the NFT pool until they exhaust their point balance.

```
function withdraw(uint256 _amount) public;
```
Allow user to withdraw `_amount` of LP tokens. Reverts if `_amount` exceeds deposited LP tokens by user.

```
function exit() external;
```
Allow user to claim random NFTs and withdraw all LP tokens from contract.

---
## Local Project Set Up:
1. Install Required packages.
```npm i```

2. Compile contracts
```truffle compile```

3. Run tests. Run these commands parallelly, one after another:
```ganache-cli```
```npm run tests```

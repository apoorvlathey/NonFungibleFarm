# NonFungibleFarm
Farm ERC-1155 NFT by staking ERC-20 LP Tokens

**Video Explanation:** https://youtu.be/vIcf74CvsCs

## User Flow:
 * NFT's are deposited into this contract, having some Price as `points` associated to them.
 * In order to claim an NFT, the user must have sufficient `points` to reach Price threshold.
 * To increase `points` balance, user must deposit lp tokens to this contract.
 * `points` balance increases dynamically with each passing second allowing user to Farm NFTs!

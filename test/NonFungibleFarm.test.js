const { accounts, contract, web3 } = require("@openzeppelin/test-environment");
const { expect } = require("chai");
const {
  expectRevert,
  BN,
  ether,
  constants
} = require("@openzeppelin/test-helpers");

const TestNFT = contract.fromArtifact("TestERC1155")
const LPToken = contract.fromArtifact("TestERC20")
const Farm = contract.fromArtifact("NonFungibleFarm")

function advanceTime(duration) {
  const id = Date.now();

  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [duration],
        id: id
      },
      (err1) => {
        // console.log("increased with evm_mine");
        if (err1) return reject(err1);

        web3.currentProvider.send(
          {
            jsonrpc: "2.0",
            method: "evm_mine",
            id: id + 1
          },
          (err2, res) => {
            //  console.log("increased time: " + Math.round(Date.now() / 1000));
            return err2 ? reject(err2) : resolve(res);
          }
        );
      }
    );
  });
}

describe("NonFungibleFarm", () => {
  const admin = accounts[0]
  const user1 = accounts[1]

  before(async () => {
    this.testNFT = await TestNFT.new({from: admin})
    this.lpToken = await LPToken.new(user1, {from: admin})
    this.farm = await Farm.new(new BN("1"), this.lpToken.address, {from: admin})  // emission rate of 1 point per LP staked (wei) per second
  });

  it('should allow admin to list ERC-1155 NFT', async () => {
    this.testNFT.setApprovalForAll(this.farm.address, true, {from: admin})
    const iniNFTCount = await this.farm.nftCount()
    this.farm.addNFT(
      this.testNFT.address,
      "0",
      "10",
      "500",
      {
        from: admin
      }
    )
    const finalNFTCount = await this.farm.nftCount()
    expect(finalNFTCount).to.be.bignumber.gt(iniNFTCount)
  })

  it('allow user to stake LP tokens', async () => {
    await this.lpToken.approve(this.farm.address, "1000000", {from: user1})
    const iniFarmTokenBal = await this.lpToken.balanceOf(this.farm.address)
    await this.farm.deposit("1", {from: user1})
    const finalFarmTokenBal = await this.lpToken.balanceOf(this.farm.address)
    expect(finalFarmTokenBal).to.be.bignumber.gt(iniFarmTokenBal)
  });

  it('should increase user Points balance after 700 seconds passed', async () => {
    const iniPointsBal = await this.farm.pointsBalance(user1)
    await advanceTime("700")
    const finalPointsBal = await this.farm.pointsBalance(user1)
    expect(finalPointsBal).to.be.bignumber.gt(iniPointsBal)
  });

  it('should allow user to claim farmed NFT', async () => {
    const iniNFTBal = await this.testNFT.balanceOf(user1, "0")
    await this.farm.claim("0", "1", {from: user1})
    const finalNFTBal = await this.testNFT.balanceOf(user1, "0")
    expect(finalNFTBal).to.be.bignumber.gt(iniNFTBal)
  });

  it('should allow user to unstake lp tokens', async () => {
    const iniLPBal = await this.lpToken.balanceOf(user1)
    const stakedBal = (await this.farm.userInfo(user1)).amount
    await this.farm.withdraw(stakedBal, {from: user1})
    const finalLPBal = await this.lpToken.balanceOf(user1)
    expect(finalLPBal).to.be.bignumber.gt(iniLPBal)
  })
  
})
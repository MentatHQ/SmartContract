const MNFT = artifacts.require("./MNFT.sol");
let token;

contract("MNFT", accounts => {
  it("should deploy and mint new token", async () => {
    token = await MNFT.new("Mentat NFT", "MNFT");
    await token.mint("Javscript", 5, { from: accounts[0] });

    assert.equal(await token.name(), "Mentat NFT");
    assert.equal(await token.symbol(), "MNFT");
    assert.equal(await token.exists(1), true);
    assert.equal(await token.ownerOf(1), accounts[0]);
  });

  it("should burn token", async () => {
    token = await MNFT.new("Mentat NFT", "MNFT");
    await token.mint("Javscript", 5, { from: accounts[0] });
    await token.burn(1, { from: accounts[0] });

    assert.equal(await token.exists(1), false);
  });
});

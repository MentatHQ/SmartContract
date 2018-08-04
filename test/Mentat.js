const Mentat = artifacts.require("./Mentat.sol");
const MentatToken = artifacts.require("./MentatToken.sol");
let mentat;
let mentatToken;

contract("Mentat", accounts => {
  it("should initialize token and Mentat", async () => {
    mentat = await Mentat.at(Mentat.address);
    mentatToken = await MentatToken.at(MentatToken.address);

    mentat.setMentatToken(mentatToken.address);
    mentatToken.setMentat(mentat.address);
  });

  it("agent should sign up", async () => {
    await mentat.agentSignUp("Dragonborn", "Dovahkiin@mentat.org");
    const agent = await mentat.agents(accounts[0]);
    assert.equal(agent[0], "Dragonborn");
    assert.equal(agent[1], "Dovahkiin@mentat.org");
  });

  it("agent should sign out", async () => {
    await mentat.agentSignOut();
  });

  it("agent should sign in", async () => {
    await mentat.agentSignIn();
  });

  it("should check agent last action timestamp", async () => {
    const lastActionTimestamp = (await mentat.agents(accounts[0]))[5];
    assert.equal(
      lastActionTimestamp.toString(10),
      web3.eth.getBlock(web3.eth.blockNumber).timestamp
    );
  });

  it("should check if agent online", async () => {
    assert.equal(await mentat.isAgentOnline(accounts[0]), true);
  });

  it("agent should update data", async () => {
    await mentat.agentUpdateAccount("Dovahkiin", "Dragonborn@mentat.org");
    const agent = await mentat.agents(accounts[0]);
    assert.equal(agent[0], "Dovahkiin");
    assert.equal(agent[1], "Dragonborn@mentat.org");
  });

  it("should get current task for agent (empty)", async () => {
    try {
      const task = await mentat.agentGetCurrentTask();
      throw "exists";
    } catch (e) {
      assert.notEqual(e, "exists", "task exists");
    }
  });

  it("should get current task type", async () => {
    assert.equal(await mentat.agentGetCurrentTaskType(), false);
  });

  //TODO accept task (should implement buyer logic first)

  it("should withdraw agent payment", async () => {});

  it("should get agent token balance", async () => {
    assert.equal(await mentat.getTokenBalance(), 0);
  });

  it("should assign task", async () => {});

  it("should assign review", async () => {});

  it("should calculate task price", async () => {});
});

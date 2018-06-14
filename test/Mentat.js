const Mentat = artifacts.require("./Mentat.sol");
let mentat;

contract('Mentat', (accounts) => {

    it("agent should sign up", async () => {
        mentat = await Mentat.at(Mentat.address);
        await mentat.agentSignUp("Dragonborn", "Dovahkiin@mentat.org");
        const agent = await mentat.agents(accounts[0]);
        assert.equal(agent[0], "Dragonborn");
        assert.equal(agent[1], "Dovahkiin@mentat.org");
        console.log("Congratulations, " + agent[0] + "! We have some work for you.");
    });

    it("agent should sign out", async () => {
        await mentat.agentSignOut();
    });

    it("agent should sign in", async () => {
        await mentat.agentSignIn();
    });

    it("should check agent last action timestamp", async () => {
        const lastActionTimestamp = (await mentat.agents(accounts[0]))[5];
        assert.equal(lastActionTimestamp.toString(10), web3.eth.getBlock(web3.eth.blockNumber).timestamp);
    });

    it("should check if agent online", async () => {
        assert.equal(await mentat.isAgentOnline(accounts[0]), true);
    });

    it("agent should update data", async () => {
        await mentat.agentUpdateAccount("Dovahkiin", "Dragonborn@mentat.org");
        const agent = await mentat.agents(accounts[0]);
        assert.equal(agent[0], "Dovahkiin");
        assert.equal(agent[1], "Dragonborn@mentat.org");
        console.log("Welcome back, " + agent[0]);
    });

    //TODO
    it("should get agent's task", async () => {
        //const mentat = await Mentat.new();
        const task = await mentat.agentGetTask();
        console.log(task);
    });


});

const Mentat = artifacts.require("./Mentat.sol");
let mentat;

contract('Mentat', (accounts) => {

    it("agent should sign up", async () => {
        mentat = await Mentat.at(Mentat.address);
        await mentat.agentSignUp("Dovahkiin", "dragonborn@mentat.org");
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

    it("should return True if agent data was update correctly", async () => {
        mentat = await Mentat.new("NewNameOfTheAgent", "NewEmailOfTheAgent");
        const task = await mentat.agentUpdateAccount();
        console.log(task);
    });

    //TODO
    it("should get agent's task", async () => {
        //const mentat = await Mentat.new();
        const task = await mentat.agentGetTask();
        console.log(task);
    });


});

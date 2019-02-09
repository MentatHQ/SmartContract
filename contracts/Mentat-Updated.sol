pragma solidity >=0.4.23;

import "./MentatToken.sol";

contract MentatCore {

    /////
    // Storage
    ///////////////////////////////

    uint minimumWage = 2 finney; //0.002 ETH/min
    uint capacityPremium = 125;
    address public owner;  // contract´s creator
    address public mentatToken;

    struct Skill {
        uint skillID;
        bytes32 name;
        uint skillLevelMultiplier;
    }
    mapping(uint => Skill) public skills;
    uint public skillsCount;

    struct AgentSkill {
        uint skillID;
        uint level; //min 1, max 5
        uint experience; //levels up after 1000 for each level
    }
    struct Agent {
        uint tokensStaked;
        mapping(uint => AgentSkill) agentSkills;
        uint agentSkillsCount;
        uint tasksCompleted;
    }
    mapping(address => Agent) public agents;

    enum TaskStatus {
        Opened, // buyer opens and pays for task
        Accepted, // // agent accepts task
        Completed, // buyer or agent marks task as complete
        Canceled // buyer cancels task and receives refund
    }
    
    struct Task {
        address agent;
        address buyer;
        uint skillID;
        uint skillLevel;
        uint experience;
        uint rate; //per minute
        uint expectedDuration;  //in minutes
        uint expectedPrice; //rate * duration
        TaskStatus status;
        uint acceptedTime; //DateTime
        uint completeTime;  //DateTime
        uint expiration; //DateTime
        bool negativeReview;
    }
    mapping(uint => Task) public tasks;
    uint public tasksCount;

    ////
    // Modifiers
    ///////////////

    // check that address has staked any tokens
    modifier checkAgentIsRegistered(address _address) {
        require(agents[_address].registrationTimestamp > 0);
        _;
    }

    //check that address has not staked any tokens
    modifier isNotAgentRegistered(address _address) {
        require(agents[_address].registrationTimestamp == 0);
        _;
    }

    modifier onlyOwner(address _address) {
        require(_address == owner);
        _;
    }

    ////
    // Public methods
    ///////////////

    constructor() public {
        owner = msg.sender;
    }

    function setMentatToken(address mentatTokenAddress)
    onlyOwner(msg.sender) public {
        mentatToken = mentatTokenAddress;
    }

    //agent needs to stake tokens with this method
    function agentSignUp(uint tokensAmount)
    isNotAgentRegistered(msg.sender) public {
        //does this account for tokensAmount being fractional?
        MentatToken(mentatToken).transferFrom(msg.sender, this, tokensAmount);
        agents[msg.sender].tokensStaked += tokensAmount;
    }

    function acceptTask(uint taskId) public {
        require(tasks[taskId].agent == msg.sender);
        
        tasks[taskId].status = TaskStatus.Accepted;
        tasks[taskId].acceptedTime = now;
    }

    function rejectTask(uint taskId) public {
        require(tasks[taskId].agent == msg.sender);

        // needs to notify server and sent agent offline

        //needs to call assign task to new agent
    }

    function completeTask(uint taskId) public {
        require(tasks[taskId].agent == msg.sender || tasks[taskID].buyer == msg.sender);

        tasks[taskId].status = TaskStatus.Completed;
        tasks[taskId].completeTime = now;

        //send "change" if completed early
        uint actualDuration = now - tasks[taskId].acceptedTime;
        if(actualDuration < expectedDuration * 1 minutes) {
            uint refund = (actualDuration - expectedDuration) * tasks[taskId].rate;
            Transfer(this, msg.sender, refund);
        }

        //needs to notify server
    }

    //needs to get rate from server
    function createTask(uint _skillID, uint _skillLevel, uint _rate, uint _expectedDuration) public payable {
        require(1 <= _skillLevel && _skillLevel <= 5);

        tasksCount++;

        tasks[tasksCount].buyer = msg.sender;
        tasks[tasksCount].skillID = _skillID;
        tasks[tasksCount].skillLevel = _skillLevel;
        tasks[tasksCount].experience = skills[_skillID].skillLevelMultiplier * _skillLevel;
        tasks[tasksCount].status = TaskStatus.Opened;
        tasks[tasksCount].rate = _rate;
        tasks[tasksCount].expectedDuration = _expectedDuration;
        tasks[tasksCount].expectedPrice = _expectedDuration * tasks[tasksCount].rate * capacityPremium;
        require(msg.value == tasks[tasksCount].expectedPrice);

        //needs to call assign task
    }

    //create a task in an inactive skill market
    //rate is inputted by the user (in ethers)
    function createGenesisTask(uint _skillID, uint _skillLevel, uint _rate, uint _expectedDuration) public payable {
        require(1 <= _skillLevel && _skillLevel <= 5);

        tasksCount++;

        tasks[tasksCount].buyer = msg.sender;
        tasks[tasksCount].skillID = _skillID;
        task[tasksCount].skillLevel = _skillLevel;
        tasks[tasksCount].experience = skills[_skillID].skillLevelMultiplier * _skillLevel;
        tasks[tasksCount].status = TaskStatus.Opened;
        tasks[tasksCount].rate = _rate * 1 ether;
        require(tasks[tasksCount].rate >= minimumWage);
        tasks[tasksCount].expectedDuration = _expectedDuration;
        tasks[tasksCount].expectedPrice = _expectedDuration * tasks[tasksCount].rate * capacityPremium;
        require(msg.value == tasks[tasksCount].expectedPrice);
    }

    function cancelTask(uint _taskID) public {
        require(msg.sender == tasks[_taskID].buyer);
        tasks[_taskID].status = TaskStatus.Canceled;

        //send refund
        Transfer(this, msg.sender,tasks[_taskID].expectedPrice);
    }
    
    function reviewTask(uint _taskID, bool _reviewResult) public {
        require(msg.sender == tasks[_taskID].buyer);
        tasks[_taskID].negativeReview == _reviewResult;

        //needs to slash experience and stake (and redistribute) if review is negative
    }

    function withdrawPayment(uint taskId) public {
        uint skillID = tasks[taskId].skillID;
        //needs to check that this agent completed the task
        require(tasks[taskId].agent == msg.sender);
        require(tasks[taskId].status == TaskStatus.Completed);

        uint gainedExperience = tasks[taskId].experience;
        agents[msg.sender].agentSkills[skillID].experience += gainedExperience;
        //level up until level 5
        if (agents[msg.sender].agentSkills[skillID].experience >= 1000 && agents[msg.sender].agentSkills[skillID].level < 5) {
            agents[msg.sender].agentSkills[skillID].level++;
            agents[msg.sender].agentSkills[skillID].experience -= 1000;
        }
        //needs to mint new MNFT and burn old one
        
        //withdraw payment
        msg.sender.transfer(getTaskPrice(taskId));
    }

    function withdrawTokens(uint tokensAmount) public {
        require(agents[msg.sender].tokensStaked >= tokensAmount);
        MentatToken(mentatToken).transferFrom(this, msg.sender, tokensAmount);
        agents[msg.sender].tokensStaked -= tokensAmount;
    }

    function agentAddSkill(uint _skillId)
    checkAgentIsRegistered(msg.sender) public {
        agents[msg.sender].agentSkillsCount++;
        uint agentSkillsCount = agents[msg.sender].agentSkillsCount;
        agents[msg.sender].agentSkills[agentSkillsCount] = AgentSkill({
            skillID: _skillId,
            level: 1,
            experience: 0
        });

        //needs to mint MNFT
    }

    function getAgentSkills(address agent) view
    checkAgentIsRegistered(agent) 
    public returns (uint[]) {
        uint[] agentSkillsArray;
        uint agentSkillsCount = agents[agent].agentSkillsCount;
        for (uint i = 1; i <= agentSkillsCount; i++) {
            agentSkillsArray.push(agents[agent].agentSkills[i].skillID);
        }
        return agentSkillsArray;   
    }

    function createSkill(bytes32 _name, uint _skillLevelMultiplier) public {
        skillsCount++;
        
        skills[skillsCount].skillID = skillsCount;
        skills[skillsCount].name = _name;
        skills[skillsCount].skillLevelMultiplier = _skillLevelMultiplier;
    }  

    function getSkillData(uint skillID) view
    checkAgentIsRegistered(msg.sender) 
    public returns(uint level, bytes32 name) {
        level = agents[msg.sender].agentSkills[skillID].level;
        name = agents[msg.sender].agentSkills[skillID].name;
        return;
    }

    function getTokenBalance(address agent) view public returns(uint) {
        return MentatToken(mentatToken).balanceOf(agent);
    }

    ////
    // Internal methods
    ///////////////

    function assignTask(uint taskID) internal {
        require(tasks[taskID].status == TaskStatus.Paid);

        // needs to get eligible agents from server
        // probabilistically match agent (based on token balance) and notify server
        address assignedAgent;
        tasks[taskID].agent = assignedAgent;
    }

}
pragma solidity ^0.4.23;

import "./MentatToken.sol";

contract Mentat {

    /////
    // Storage
    ///////////////////////////////

    uint taskRejectionsLimit = 3;
    address public owner;  // contract´s creator
    address public mentatToken;
    enum SkillType {Skill, Expertise}
    enum TaskStatus {
        Opened, // waiting for a payment
        Paid, // buyer should pay right after the opening
        Matched, // agent is matched for the task
        Accepted, // // agent accepted the task
        Rejected, // after N rejections
        Completed, // agent answered
        Reviewed // the third review is done
    }

    struct Skill {
        uint skillID;
        bytes32 name;
        SkillType skill;
        uint skillLevelMultiplier;
    }

    mapping(uint => Skill) public skills;
    uint public skillsCount;

    struct Agent {
        bytes32 name;
        bytes32 email;
        bool isBusy;
        mapping(uint => AgentSkill) agentSkills;
        uint agentSkillsCount;
        uint registrationTimestamp; // DateTime
        uint lastActionTimestamp; //DateTime
        uint tasksCompleted;
        uint tasksRejected;
        uint agentsReviews;
        uint currentTaskId;
        bool currentTaskType; // 1 - task, 0 - review
        uint blockedUntilTimestamp;
    }

    mapping(address => Agent) public agents;

    struct AgentSkill {
        uint skillID;
        uint level;
    }

    struct TaskBundle1 {
        uint applicationID;
        address agent;
        address buyer;
        uint skillID;
        uint skillLevel;
        uint experience;
        bytes32 request;
        bytes32 response;
        bytes32 description;
        TaskStatus status;
        mapping(uint => address) rejectedAgents;
        uint rejectedAgentsCount;
        uint createdTimestamp;  //DateTime
        uint lastUpdateTimestamp; //DateTime
    }

    struct TaskBundle2 {
        address reviewAgent1;
        address reviewAgent2;
        address reviewAgent3;
        bool reviewResult1;
        bool reviewResult2;
        bool reviewResult3;
        uint expectedPrice;
        uint price;
        uint tokensAmount;
        bool withdrawn;
        bool tokensWithdrawn;
        uint expectedCompleteTime;  //DateTime
        uint completeTime;  //DateTime
    }

    mapping(uint => TaskBundle1) public tasksBundle1;
    mapping(uint => TaskBundle2) public tasksBundle2;
    uint public tasksCount;

    struct Application {
        bytes32 name;
    }

    mapping(uint => Application) public applications;
    uint public applicationsCount;

    ////
    // Events
    ///////////////

    event SUCCESS(bytes32 message);
    event FAIL(bytes32 message);

    ////
    // Modifiers
    ///////////////

    modifier checkAgentIsRegistered(address _address) {
        require(agents[_address].registrationTimestamp > 0);
        _;
    }

    modifier isNotAgentRegistered(address _address) {
        require(agents[_address].registrationTimestamp == 0);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMentatToken() {
        require(msg.sender == mentatToken);
        _;
    }

    modifier checkAgentIsNotBusy(address agent) {
        require(!agentIsBusy(agent));
        _;
    }

    modifier checkIsNotBlocked(address agent) {
        require(agents[agent].blockedUntilTimestamp < now);
        _;
    }


    ////
    // Public methods
    ///////////////

    constructor() public {
        owner = msg.sender;
    }

    function setMentatToken(address newMentatToken)
    onlyOwner
    public {
        mentatToken = newMentatToken;
    }

    function agentSignIn()
    checkAgentIsRegistered(msg.sender)
    checkIsNotBlocked(msg.sender)
    public {
        agentUpdateOnline(msg.sender);
        agents[msg.sender].tasksRejected = 0;
        emit SUCCESS("signedIn");
    }

    function agentSignOut()
    checkAgentIsRegistered(msg.sender)
    public {
        agents[msg.sender].lastActionTimestamp = 0;
        emit SUCCESS("signedOut");
    }

    function agentSignUp(bytes32 _name, bytes32 _email)
    isNotAgentRegistered(msg.sender)
    public {
        agents[msg.sender] = Agent({
            name : _name,
            email : _email,
            isBusy : false,
            agentSkillsCount : 0,
            registrationTimestamp : now,
            lastActionTimestamp : now,
            tasksCompleted : 0,
            tasksRejected : 0,
            agentsReviews : 0,
            currentTaskId : 0,
            currentTaskType : false,
            blockedUntilTimestamp : 0
            });
        emit SUCCESS("signedUp");
    }

    function isAgentRegistered(address agent) public view
    checkAgentIsRegistered(agent)
    returns (bool)
    {
        return true;
    }

    function isAgentOnline(address agent) public view
    checkAgentIsRegistered(agent)
    returns (bool) {
        return ((now - agents[agent].lastActionTimestamp) < 1 hours);
    }

    function agentUpdateAccount(bytes32 _name, bytes32 _email)
    checkAgentIsRegistered(msg.sender)
    public {
        agents[msg.sender].name = _name;
        agents[msg.sender].email = _email;
        agentUpdateOnline(msg.sender);
        emit SUCCESS("agentAccountUpdated");
    }

    function agentStartReview(uint _taskID) public
    checkAgentIsRegistered(msg.sender)
    checkIsNotBlocked(msg.sender)
    returns (bool) {
        require(!agentIsBusy(msg.sender));
        agents[msg.sender].isBusy = true;
        agents[msg.sender].currentTaskId = _taskID;
        agents[msg.sender].currentTaskType = false;
        if (tasksBundle2[_taskID].reviewAgent1 != address(0)) {
            if (tasksBundle2[_taskID].reviewAgent2 != address(0)) {
                if (tasksBundle2[_taskID].reviewAgent3 != address(0)) {
                    return false;
                } else {
                    tasksBundle2[_taskID].reviewAgent3 = msg.sender;
                }
            } else {
                tasksBundle2[_taskID].reviewAgent2 = msg.sender;
            }
        } else {
            tasksBundle2[_taskID].reviewAgent1 = msg.sender;
        }
        tasksBundle1[_taskID].lastUpdateTimestamp = now;
        agentUpdateOnline(msg.sender);
        emit SUCCESS("agentReviewStarted");
    }

    function agentFinishReview(uint _taskID, bool _result) public
    checkAgentIsRegistered(msg.sender)
    checkIsNotBlocked(msg.sender)
    returns (bool) {
        agents[msg.sender].isBusy = false;
        agents[msg.sender].agentsReviews++;
        agents[msg.sender].currentTaskId = 0;
        if (tasksBundle2[_taskID].reviewAgent1 != msg.sender) {
            if (tasksBundle2[_taskID].reviewAgent2 != msg.sender) {
                if (tasksBundle2[_taskID].reviewAgent3 != msg.sender) {
                    return false;
                } else {
                    tasksBundle2[_taskID].reviewResult3 = _result;
                }
            } else {
                tasksBundle2[_taskID].reviewResult2 = _result;
            }
        } else {
            tasksBundle2[_taskID].reviewResult1 = _result;
        }
        tasksBundle1[_taskID].lastUpdateTimestamp = now;
        tasksBundle1[_taskID].status = TaskStatus.Reviewed;
        agentUpdateOnline(msg.sender);
        emit SUCCESS("agentReviewFinished");
    }

    function getTaskPrice(uint _taskID) public view
    returns (uint)  {
        return tasksBundle2[_taskID].price;
    }

    function agentGetCurrentTaskType() public view
    checkAgentIsRegistered(msg.sender)
    returns (bool) {
        return agents[msg.sender].currentTaskType;
    }

    function changeAgent(uint _taskID) public
    checkAgentIsRegistered(msg.sender) {
        agents[msg.sender].isBusy = true;
        agents[msg.sender].lastActionTimestamp = now;
        agents[msg.sender].currentTaskId = _taskID;
        agents[msg.sender].currentTaskType = true;
        tasksBundle1[_taskID].agent = msg.sender;
        tasksBundle1[_taskID].status = TaskStatus.Matched;
        tasksBundle1[_taskID].lastUpdateTimestamp;
    }

    function agentGetCurrentTask() public view
    checkAgentIsRegistered(msg.sender)
    checkAgentIsNotBusy(msg.sender)
    checkIsNotBlocked(msg.sender)
    returns (uint taskId, bool taskType, bytes32 applicationName, bytes32 description) {
        taskType = agents[msg.sender].currentTaskType;
        taskId = agents[msg.sender].currentTaskId;
        require(taskId > 0);
        uint applicationId = tasksBundle1[taskId].applicationID;
        applicationName = applications[applicationId].name;
        description = tasksBundle1[taskId].description;
        return;
    }

    function acceptTask(uint taskId, address agent, uint tokensAmount)
    onlyMentatToken
    checkAgentIsNotBusy(agent)
    checkIsNotBlocked(agent)
    public {
        tasksBundle1[taskId].status = TaskStatus.Accepted;
        tasksBundle1[taskId].lastUpdateTimestamp = now;
        tasksBundle2[taskId].tokensAmount = tokensAmount;
        //agents[agent].isBusy = true; // should set after the last review
        agentUpdateOnline(agent);
    }

    function rejectTask()
    checkAgentIsNotBusy(msg.sender)
    checkIsNotBlocked(msg.sender)
    public {
        agentUpdateOnline(msg.sender);
        uint taskId = agents[msg.sender].currentTaskId;

        agents[msg.sender].currentTaskId = 0;
        agents[msg.sender].tasksRejected += 1;
        tasksBundle1[taskId].rejectedAgentsCount += 1;

        if (agents[msg.sender].tasksRejected > taskRejectionsLimit) {
            agents[msg.sender].tasksRejected = 0;
            agents[msg.sender].blockedUntilTimestamp = now + 1 hours;
        }

        //TODO call assign task to new agent
    }

    function completeTask(bytes32 response)
    checkIsNotBlocked(msg.sender)
    public {

        agentUpdateOnline(msg.sender);
        uint taskId = agents[msg.sender].currentTaskId;
        require(agentIsBusy(msg.sender));
        require(tasksBundle1[taskId].agent == msg.sender);

        tasksBundle1[taskId].status = TaskStatus.Completed;
        tasksBundle1[taskId].lastUpdateTimestamp = now;
        tasksBundle1[taskId].response = response;
        tasksBundle2[tasksCount].completeTime = now;

        agents[msg.sender].currentTaskId = 0;
        agents[msg.sender].isBusy = false;

        // TODO: call assign review
    }

    function addTask(uint _applicationID, address _buyer, uint _skillID, uint _skillLevel, uint _skillMultiplier, bytes32 _request, uint _expectedPrice, uint _expectedCompleteTime) public {
        tasksCount++;

        tasksBundle1[tasksCount].applicationID = _applicationID;
        tasksBundle1[tasksCount].agent = address(0);
        tasksBundle1[tasksCount].buyer = _buyer;
        tasksBundle1[tasksCount].skillID = _skillID;
        tasksBundle1[tasksCount].skillLevel = _skillLevel;
        tasksBundle1[tasksCount].request = _request = _request;
        tasksBundle1[tasksCount].response = "";
        tasksBundle1[tasksCount].description = "";
        tasksBundle1[tasksCount].status = TaskStatus.Opened;
        tasksBundle1[tasksCount].rejectedAgentsCount = 0;
        tasksBundle1[tasksCount].createdTimestamp = now;
        tasksBundle1[tasksCount].lastUpdateTimestamp = now;

        tasksBundle2[tasksCount].reviewAgent1 = address(0);
        tasksBundle2[tasksCount].reviewAgent2 = address(0);
        tasksBundle2[tasksCount].reviewAgent3 = address(0);
        tasksBundle2[tasksCount].reviewResult1 = false;
        tasksBundle2[tasksCount].reviewResult2 = false;
        tasksBundle2[tasksCount].reviewResult3 = false;
        tasksBundle2[tasksCount].expectedPrice = _expectedPrice;
        tasksBundle2[tasksCount].price = 0;
        tasksBundle2[tasksCount].tokensAmount = 0;
        tasksBundle2[tasksCount].withdrawn = false;
        tasksBundle2[tasksCount].tokensWithdrawn = false;
        tasksBundle2[tasksCount].expectedCompleteTime = _expectedCompleteTime;
        tasksBundle2[tasksCount].completeTime = 0;
    }

    function sendPayment(uint taskId) public payable {
        require(tasksBundle1[taskId].status == TaskStatus.Opened);
        require(msg.value == tasksBundle2[taskId].price);

        tasksBundle1[taskId].agent.transfer(msg.value);
        tasksBundle1[taskId].status = TaskStatus.Paid;
        tasksBundle1[taskId].lastUpdateTimestamp = now;
    }

    function withdrawPayment() 
    checkAgentIsRegistered(msg.sender) 
    checkAgentIsNotBusy(msg.sender) 
    checkIsNotBlocked(msg.sender) 
    public {
        uint taskId = agents[msg.sender].currentTaskId;

        require(tasksBundle1[taskId].agent == msg.sender);
        require(tasksBundle1[taskId].status == TaskStatus.Reviewed);

        //withdrawn tokens
        MentatToken(mentatToken).transfer(msg.sender, tasksBundle2[taskId].tokensAmount);
        tasksBundle2[taskId].tokensWithdrawn = true;

        //withdrawn payment (ETH)
        msg.sender.transfer(tasksBundle2[taskId].price);
        tasksBundle2[taskId].withdrawn = true;

        agentUpdateOnline(msg.sender);
        tasksBundle1[taskId].lastUpdateTimestamp = now;
    }

    function agentAddSkill(uint _skillId) public
    checkAgentIsRegistered(msg.sender) 
    checkAgentIsNotBusy(msg.sender) 
    checkIsNotBlocked(msg.sender)  
    returns(bool) {
        agentUpdateOnline(msg.sender);
        agents[msg.sender].agentSkillsCount++;
        uint agentSkillsCount = agents[msg.sender].agentSkillsCount;
        agents[msg.sender].agentSkills[agentSkillsCount] = AgentSkill({
            skillID: _skillId,
            level: 1
        });
        return true;
    }

    function getAgentSkills(address agent) public
    checkAgentIsRegistered(msg.sender) 
    checkAgentIsNotBusy(msg.sender) 
    checkIsNotBlocked(msg.sender)
    returns(uint[]) {
        uint[] ids;
        uint agentSkillsCount = agents[agent].agentSkillsCount;
        for (uint i = 0; i < agentSkillsCount; i++) {
            ids.push(agents[agent].agentSkills[i].skillID);
        }
        return ids;    
    }

    function createSkill(uint _skillID, bytes32 _name, SkillType _skill, uint _skillLevelMultiplier) public {
        skillsCount++;
        
        skills[skillsCount].skillID = _skillID;
        skills[skillsCount].name = _name;
        skills[skillsCount].skill = _skill;
        skills[skillsCount].skillLevelMultiplier = _skillLevelMultiplier;
    }

    ////
    // Internal methods
    ///////////////
    function agentUpdateOnline(address agent)
    internal
    {
        agents[agent].lastActionTimestamp = now;
    }

    function agentIsBusy(address agent) view
    internal
    returns (bool)
    {
        return (agents[agent].isBusy);
    }

}

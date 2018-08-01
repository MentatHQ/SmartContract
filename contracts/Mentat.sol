pragma solidity ^0.4.23;

import "./MentatToken.sol";

contract Mentat {

    /////
    // Storage
    ///////////////////////////////

    uint taskRejectionsLimit = 3;
    uint minimumWage = 20 finney; //0.02 ETH
    uint capacityPremium = 125;
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
        mapping(uint => address) agents; //agents who have joined this pool
        uint agentsCount;
    }

    mapping(uint => Skill) public skills;
    uint public skillsCount;

    struct Agent {
        bytes32 name;
        bytes32 email;
        bool isBusy;
        mapping(uint => AgentSkill) agentSkills;
        uint agentSkillsCount;
        bool inPool;
        uint registrationTimestamp; // DateTime
        uint lastActionTimestamp; //DateTime
        uint tasksCompleted;
        uint tasksRejected;
        uint agentsReviews;
        uint currentTaskId;
        bool currentTaskType; // true - task, false - review
        uint blockedUntilTimestamp;
    }

    mapping(address => Agent) public agents;
    uint public agentsCount;

    struct AgentSkill {
        uint skillID;
        uint level;
        bytes32 name;
        SkillType skill;
    }

    struct TaskBundle1 {
        address agent;
        address buyer;
        uint skillID;
        uint skillLevel;
        uint experience;
        bytes32 request;
        bytes32 response;
        TaskStatus status;
        uint rejectedAgentsCount;
        uint createdTimestamp;  //DateTime
        uint lastUpdateTimestamp; //DateTime
    }

    struct TaskBundle2 {
        address reviewAgent1;
        address reviewAgent2;
        address reviewAgent3;
        bool reviewResult1; //true - approved, false - denied
        bool reviewResult2; //true - approved, false - denied
        bool reviewResult3; //true - approved, false - denied
        uint approvedCount;
        uint price; //per minute
        uint expectedPrice; //total price
        uint tokensAmount;
        bool withdrawn;
        bool tokensWithdrawn;
        mapping(uint => address) eligibleAgents; //agents who will receive tokens if this tasks is not approved
        uint eligibleAgentsCount;
        uint expectedCompleteTime;  //Duration
        uint completeTime;  //Duration
    }

    mapping(uint => TaskBundle1) public tasksBundle1;
    mapping(uint => TaskBundle2) public tasksBundle2;
    uint public tasksCount;

    struct Application {
        bytes32 name;
        uint registrationTimestamp;
    }

    mapping(address => Application) public applications;
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

    modifier checkAppIsRegistered(address _address) {
        require(applications[_address].registrationTimestamp > 0);
        _;
    }

    modifier isNotAppRegistered(address _address) {
        require(applications[_address].registrationTimestamp == 0);
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
            inPool: false,
            registrationTimestamp : now,
            lastActionTimestamp : now,
            tasksCompleted : 0,
            tasksRejected : 0,
            agentsReviews : 0,
            currentTaskId : 0,
            currentTaskType : false,
            blockedUntilTimestamp : 0
            });
        agentsCount++;    
        emit SUCCESS("signedUp");
    }

    //why is this an external method?
    function isAgentRegistered(address agent) public view
    checkAgentIsRegistered(agent)
    returns (bool)
    {
        return true;
    }

    //why is this an external method?
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
                    if (_result == true) {
                        tasksBundle2[_taskID].approvedCount++;
                    }
                }
            } else {
                tasksBundle2[_taskID].reviewResult2 = _result;
                if (_result == true) {
                    tasksBundle2[_taskID].approvedCount++;
                }
            }
        } else {
            tasksBundle2[_taskID].reviewResult1 = _result;
            if (_result == true) {
                tasksBundle2[_taskID].approvedCount++;
            }
        }
        tasksBundle1[_taskID].lastUpdateTimestamp = now;
        tasksBundle1[_taskID].status = TaskStatus.Reviewed;
        agentUpdateOnline(msg.sender);
        emit SUCCESS("agentReviewFinished");
    }

    //what do we need this method for?
    function getTaskPrice(uint _taskID) public view
    returns (uint)  {
        return tasksBundle2[_taskID].price;
    }

    //what do we need this method for?
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
    returns (uint taskId, bool taskType, bytes32 applicationName) {
        taskType = agents[msg.sender].currentTaskType;
        taskId = agents[msg.sender].currentTaskId;
        require(taskId > 0);
        address buyer = tasksBundle1[taskId].buyer;
        applicationName = applications[buyer].name;
        return;
    }

    function acceptTask(uint taskId, address agent, uint tokensAmount)
    onlyMentatToken
    checkAgentIsNotBusy(agent)
    checkIsNotBlocked(agent)
    public {
        require(tasksBundle1[taskId].agent == msg.sender);
        
        agents[msg.sender].currentTaskType = true;
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
        require(tasksBundle1[taskId].agent == msg.sender);
        agentUpdateOnline(msg.sender);
        uint taskId = agents[msg.sender].currentTaskId;

        agents[msg.sender].currentTaskId = 0;
        agents[msg.sender].tasksRejected += 1;
        tasksBundle1[taskId].rejectedAgentsCount += 1;
        agents[msg.sender].blockedUntilTimestamp = now + 1 hours;

        if (tasksBundle1[taskId].rejectedAgentsCount == taskRejectionsLimit) {
            tasksBundle1[taskId].status = TaskStatus.Rejected;
            //notify buyer that task is rejected
        }

        //TODO call assign task to new agent (make sure it doesn't re-assign to this agent)
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

        //assign all overtime tasks and 20% of non-overtime tasks for review
        if (tasksBundle1[taskId].createdTimestamp - tasksBundle2[taskId].completeTime > tasksBundle2[taskId].expectedCompleteTime || taskId % 5 == 0) {
            assignReview(taskId);
            agents[msg.sender].currentTaskId = 0;
            agents[msg.sender].isBusy = false;
        } else {
            agents[msg.sender].currentTaskId = 0;
            agents[msg.sender].isBusy = false;
            tasksBundle1[taskId].status = TaskStatus.Reviewed;
        }

    }

    function addTask(uint _skillID, uint _skillLevel, bytes32 _request, uint _expectedCompleteTime) 
    checkAppIsRegistered(msg.sender) 
    public returns (uint) {
        tasksCount++;

        tasksBundle1[tasksCount].agent = address(0);
        tasksBundle1[tasksCount].buyer = msg.sender;
        tasksBundle1[tasksCount].skillID = _skillID;
        tasksBundle1[tasksCount].skillLevel = _skillLevel;
        tasksBundle1[tasksCount].request = _request = _request;
        tasksBundle1[tasksCount].response = "";
        tasksBundle1[tasksCount].status = TaskStatus.Opened;
        tasksBundle1[tasksCount].rejectedAgentsCount = 0;
        tasksBundle1[tasksCount].createdTimestamp = now;
        tasksBundle1[tasksCount].lastUpdateTimestamp = now;

        tasksBundle2[tasksCount].reviewAgent1 = address(0);
        tasksBundle2[tasksCount].reviewAgent2 = address(0);
        tasksBundle2[tasksCount].reviewAgent3 = address(0);
        tasksBundle2[tasksCount].approvedCount = 0;
        tasksBundle2[tasksCount].price = calculatePrice(tasksCount);
        tasksBundle2[tasksCount].expectedPrice = _expectedCompleteTime * tasksBundle2[tasksCount].price;
        tasksBundle2[tasksCount].tokensAmount = 0;
        tasksBundle2[tasksCount].withdrawn = false;
        tasksBundle2[tasksCount].tokensWithdrawn = false;
        tasksBundle2[tasksCount].expectedCompleteTime = _expectedCompleteTime;

        return(tasksBundle2[tasksCount].expectedPrice);
    }

    function sendPayment(uint taskId) public 
    checkAppIsRegistered(msg.sender) 
    payable {
        require(tasksBundle1[taskId].status == TaskStatus.Opened);
        require(tasksBundle1[taskId].buyer == msg.sender);
        require(msg.value == tasksBundle2[taskId].expectedPrice);

        msg.sender.transfer(msg.value);
        tasksBundle1[taskId].status = TaskStatus.Paid;
        tasksBundle1[taskId].lastUpdateTimestamp = now;

        //Call assignTask()
        assignTask(taskId);
    }

    function withdrawPayment() 
    checkAgentIsRegistered(msg.sender) 
    checkAgentIsNotBusy(msg.sender) 
    checkIsNotBlocked(msg.sender) 
    public {
        uint taskId = agents[msg.sender].currentTaskId;

        require(tasksBundle1[taskId].agent == msg.sender);
        require(tasksBundle1[taskId].status == TaskStatus.Reviewed);

        //withdrawn tokens, only if 2/3 reviews are positive
        if (tasksBundle2[taskId].approvedCount >= 2) {
            MentatToken(mentatToken).transfer(msg.sender, tasksBundle2[taskId].tokensAmount);
        } else {
            //redistribute tokens to eligibleAgents except msg.sender
            uint totalTokens = tasksBundle2[taskId].tokensAmount;
            uint eligibleAgentsCount = tasksBundle2[taskId].eligibleAgentsCount;
            uint tokensAmount = totalTokens / eligibleAgentsCount;
            for (uint i = 1; i <= eligibleAgentsCount; i++) {
                if (tasksBundle2[taskId].eligibleAgents[i] != msg.sender) {
                    MentatToken(mentatToken).transfer(tasksBundle2[taskId].eligibleAgents[i], tokensAmount);
                }
            }
        }

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
            level: 1,
            name: skills[_skillId].name,
            skill: skills[_skillId].skill
        });
        
        return true;
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

    function createSkill(bytes32 _name, uint _skillLevelMultiplier) 
    checkAppIsRegistered(msg.sender) 
    public {
        skillsCount++;
        
        skills[skillsCount].skillID = skillsCount;
        skills[skillsCount].name = _name;
        skills[skillsCount].skill = SkillType.Skill;
        skills[skillsCount].skillLevelMultiplier = _skillLevelMultiplier;
    }

    function createExpertise(bytes32 _name, uint _skillLevelMultiplier) public {
        skillsCount++;
        
        skills[skillsCount].skillID = skillsCount;
        skills[skillsCount].name = _name;
        skills[skillsCount].skill = SkillType.Expertise;
        skills[skillsCount].skillLevelMultiplier = _skillLevelMultiplier;
    }    

    function appSignUp(bytes32 _name) isNotAppRegistered(msg.sender) public {
        applications[msg.sender] = Application({
            name: _name,
            registrationTimestamp: now
        });

        applicationsCount++;
    }

    function getSkillData(uint skillID) view
    checkAgentIsRegistered(msg.sender) 
    public returns(uint level, bytes32 name, SkillType skill) {
        level = agents[msg.sender].agentSkills[skillID].level;
        name = agents[msg.sender].agentSkills[skillID].name;
        skill = agents[msg.sender].agentSkills[skillID].skill;
        return;
    }

    function joinPool(uint skillID)
    checkAgentIsRegistered(msg.sender)
    public {
        require(agents[msg.sender].agentSkills[skillID].skillID == skillID);
        require(agents[msg.sender].inPool = false);

        skills[skillID].agentsCount++;
        uint agentsCount = skills[skillID].agentsCount;
        skills[skillID].agents[agentsCount] == msg.sender;
        agents[msg.sender].inPool = true;
    }

    function leavePool(uint skillID)
    checkAgentIsRegistered(msg.sender)
    public {
        require(agents[msg.sender].agentSkills[skillID].skillID == skillID);
        require(agents[msg.sender].inPool = true);

        uint agentsCount = skills[skillID].agentsCount;
        for (uint i = 1; i <= agentsCount; i++) {
            if (skills[skillID].agents[i] == msg.sender) {
                delete skills[skillID].agents[i];
                agents[msg.sender].inPool = false;
            }
        }
    }

    function createGenesisTask(uint _skillID, uint _skillLevel, uint _maxPrice, uint _startingPrice, bytes32 _request, uint _expectedCompleteTime) 
    checkAppIsRegistered(msg.sender) 
    public {
        
    }

    function checkTask(uint taskId) public view returns(TaskStatus) {
        return tasksBundle1[taskId].status;
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

    function assignTask(uint taskID) 
    internal {
        require(tasksBundle1[taskID].status == TaskStatus.Paid);

        //Loop through all skills
        for (uint ii = 0; ii < skillsCount; ii++) {
            //Loop through all agents in each pool
            for(uint iii = 0; iii < skills[ii].agentsCount; iii++) {
                //Check if agent is online
                if(isAgentOnline(skills[ii].agents[iii]) == true) {
                    tasksBundle2[taskID].eligibleAgentsCount++;
                    tasksBundle2[taskID].eligibleAgents[tasksBundle2[taskID].eligibleAgentsCount] = skills[ii].agents[iii];
                }
            }
        }    

        uint skillID = tasksBundle1[taskID].skillID;
        uint poolCount = skills[skillID].agentsCount;
        uint highestBalance = 0;
        for (uint i = 1; i <= poolCount; i++) {
            //Check for agents in the pool
            if(skills[skillID].agents[i] != address(0)) {
                //Check for agents with the right skill level
                if(agents[skills[skillID].agents[i]].agentSkills[skillID].level >= tasksBundle1[taskID].skillLevel) {
                    //Check for agents online
                    if(isAgentOnline(skills[skillID].agents[i]) == true) {
                        //Check for agents not busy
                        if (agentIsBusy(skills[skillID].agents[i]) == false) {
                            //Match the agent with the highest token balance
                            uint tokenBalance = MentatToken(mentatToken).balanceOf(skills[skillID].agents[i]);
                            if (tokenBalance > highestBalance) {
                                highestBalance = tokenBalance;
                                tasksBundle1[taskID].agent = skills[skillID].agents[i];
                                tasksBundle1[taskID].status = TaskStatus.Matched;
                            }
                        }
                    }
                }
            }
        }
    }

    function assignReview(uint taskID) 
    internal {
        require(tasksBundle1[taskID].status == TaskStatus.Completed);

        uint skillID = tasksBundle1[taskID].skillID;
        uint poolCount = skills[skillID].agentsCount;
        for (uint ii = 0; ii < 3; ii++) {
            for (uint i = 0; i < poolCount; i++) {
                //Check for agents in the pool
                if(skills[skillID].agents[i] != address(0)) {
                    //Check for agents with the right skill level
                    if(agents[skills[skillID].agents[i]].agentSkills[skillID].level >= tasksBundle1[taskID].skillLevel) {
                        //Check for agents online
                        if(isAgentOnline(skills[skillID].agents[i]) == true) {
                            //Check for agents not busy
                            if (agentIsBusy(skills[skillID].agents[i]) == false) {
                                //Match an agent
                                if (tasksBundle2[taskID].reviewAgent1 == address(0)) {
                                    tasksBundle2[taskID].reviewAgent1 = skills[skillID].agents[i];
                                } else if (tasksBundle2[taskID].reviewAgent2 == address(0)) {
                                    tasksBundle2[taskID].reviewAgent2 = skills[skillID].agents[i];
                                } else if (tasksBundle2[taskID].reviewAgent3 == address(0)) {
                                    tasksBundle2[taskID].reviewAgent3 = skills[skillID].agents[i];
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function calculatePrice(uint taskID) 
    internal returns (uint) {
        uint count;
        uint total = 0;
        //Loop through all tasks
        for (uint i = 1; i <= tasksCount; i++) {
            //Find tasks with this skill ID of this task
            if (tasksBundle1[i].skillID == tasksBundle1[taskID].skillID) {
                //Find tasks that are TaskStatus.Accepted
                if(tasksBundle1[i].status == TaskStatus.Accepted) {
                    //Count these tasks
                    count++; 
                    //Sum the prices of those tasks
                    total += tasksBundle2[i].price;
                }
            }
        }
        //Divide the total by number of agents online in the pool
        uint online = 0;

        uint skillID = tasksBundle1[taskID].skillID;
        uint poolCount = skills[skillID].agentsCount;
        for (uint ii = 1; ii <= poolCount; ii++) {
            //Check for agents in the pool
            if(skills[skillID].agents[ii] != address(0)) {
                //Check for agents online
                if(isAgentOnline(skills[skillID].agents[ii]) == true) {
                    online++;
                }
            }
        }
        uint unadjustedPrice = total / online;            
        //Multiply by the capacity premium
        uint adjustedPrice = unadjustedPrice * (capacityPremium / 100);
        //Return the higher of that price and the minimum wage
        if (adjustedPrice >= minimumWage) {
            return adjustedPrice;
        } else {
            return minimumWage;
        }
    }

}

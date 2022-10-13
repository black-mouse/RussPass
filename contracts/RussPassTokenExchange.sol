// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;

import "./IRussPass.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "./RussPassToken.sol";


contract RussPassTokenExchange is Ownable, IRussPass {

    RussPassToken public tokenRPT;
    // Массив для хранения названий компаний
    string[] listOFCompanies;
    // Mapping для регистрации компаний
    mapping(string => Company) public companies;
    // Mapping для регистрации клиентов
    mapping(address => Client) public clients;
    // Определяем связку баланс-адрес
													  
																										  
    mapping (address => uint256) balances;

    // Список программ лояльности в которых участвует клиент
    mapping(address => string[]) private mappingClientLoyaltyCards;
    // Связываем количество баллов с программой лояльности у клиента
    mapping(address => mapping(string => uint256)) private mappingLoyaltyPoints;
    // Список клиентов в программе лояльности компании
    mapping(address => address[]) private mappingCompanyClients;
    

    constructor(){
        tokenRPT = new RussPassToken(_msgSender(), address(this), 10000*10**2);
    }

    // Функция для генерации новых токенов
    function generateNewTokens(uint256 _numTokens) external onlyOwner {
        tokenRPT.mint(address(this), _numTokens);
    }

    // Функция для генерации новых токенов на адресс
    function generateNewTokensTo(address _address, uint256 _numTokens) external onlyOwner {
        tokenRPT.mint(_address, _numTokens);
    }

    // Количество токенов, которые можно получить за баллы
    function tokenCount(uint256 numpoints_, uint256 rate_) internal pure returns (uint256) {
        return numpoints_ / rate_ ;
    }

    // Количество баллов, которые можно получить, обменяв токены
    function pointsCount(uint256 numTokens_, uint256 rate_) internal pure returns (uint256) {
        return numTokens_ * rate_;
    }

    // Баланс токенов контракта 
    function balanceOf() public view returns (uint256) {
        return tokenRPT.balanceOf(address(this));
    }


    // Баланс токенов клиента
    function clientTokens() public view returns (uint256) {
        return tokenRPT.balanceOf(_msgSender());
    }


    // Покупка токенов
    function buyTokens(string memory loyaltyName, uint256 _tokenCount) external {
        // Получаем рейтинг баллов программы лояльности
        uint256 rate = companies[loyaltyName].rate;
        // Получаем количество балло, которые клиент может обменять за токены
        uint256 numPoints = pointsCount(_tokenCount, rate);
        // Получаем количество баллов программы лояльности у клиента
        uint256 numClientPoints = mappingLoyaltyPoints[_msgSender()][loyaltyName];

        // Проверяем, хватает ли баллов для покупки токенов
        require(
            numClientPoints >= numPoints,
            "ERROR: You don't have enough points. Buy less Tokens."
        );
        // Вычитаем баллы для покупки токенов
        numClientPoints -= numPoints;
        mappingLoyaltyPoints[_msgSender()][loyaltyName] = numClientPoints;
        // Добавляем токены на баланс клиента
        tokenRPT.transfer(_msgSender(), _tokenCount);
        // Регистрируем купленные токены
        clients[_msgSender()].tokensBuyed += _tokenCount;

        // Оповещаем блокчейн об обмене баллов на токены
        emit SellPoints(loyaltyName, numPoints, rate);
        // Оповещаем блокчейн о покупке токенов за баллы
        emit BuyRussPassTokens(loyaltyName, numPoints, rate, _tokenCount);
    }

    // Продажа токенов
    function sellTokens(string memory loyaltyName, uint256 _pointsCount) external{
        // Получаем рейтинг баллов программы лояльности
        uint256 rate = companies[loyaltyName].rate;
        // Получаем количество токенов, которые клиент может купить за баллы
        uint256 numTokens = tokenCount(_pointsCount, rate);
        // Получаем количество баллов программы лояльности у клиента
        uint256 numClientPoints = mappingLoyaltyPoints[_msgSender()][loyaltyName];

        // Получение количества доступных токенов на балансе
        uint256 balance = clientTokens();
        // Проверка, хватает ли токенов клиенту, чтобы купить баллы
        require(
            numTokens <= balance,
            "ERROR: You don't have enough tokens. Buy a smaller number of Points"
        );
        // Сжигаем токены, обмененные на баллы
        tokenRPT.burn(_msgSender(), numTokens);
        // Записываем клиенту трату токенов
        clients[_msgSender()].tokensBuyed -= numTokens;
        // Регистрируем купленные баллы
        numClientPoints += _pointsCount;
        mappingLoyaltyPoints[_msgSender()][loyaltyName] = numClientPoints;

        // Оповещаем блокчейн о покупке баллов для программы лояльности
        emit BuyPoints(loyaltyName, _pointsCount, rate);
        // Оповещаем блокчейн о продаже токенов, чтобы клиенту начислили баллы
        emit SellRussPassTokens(loyaltyName, numTokens, rate, _pointsCount);
    }
										   																					
	  
    // Добавляение нового клиента
    function addClient(address addr, uint256 tokensBuyed) external onlyOwner {
        // Добавление нового клиента в mapping
        clients[addr] = Client(
            addr,
            tokensBuyed
        );
        // Добавляем событие добавления клиента
        emit AddClient(addr);
    }

    // Клиент может подключить программу лояльности
    function addLoyaltyProgram(string memory loyaltyName, uint256 _pointsCount) external {
        // Записываем в маппинг программу лояльности для клиента
        mappingClientLoyaltyCards[_msgSender()].push(loyaltyName);
        // Записываем количество баллов для программы лояльности 
        mappingLoyaltyPoints[_msgSender()][loyaltyName] = _pointsCount;
        // Находим адрес компании по лояльности
        address addrComp = companies[loyaltyName].addr;
        // Добавляем клиента в список для компании
        mappingCompanyClients[addrComp].push(_msgSender());
        // Добавляем событие добавления клиентом программы лояльности
        emit AddLoyaltyProgram(loyaltyName, _msgSender());
    }

    // Клиент может посмотретьть свой список программ лояльности
    function showClientLoyaltyCards() external view returns (string[] memory) {
        return mappingClientLoyaltyCards[_msgSender()];
    }

    
    function getPoints(string memory loyaltyName) external view returns (uint256) {
        return  mappingLoyaltyPoints[_msgSender()][loyaltyName];
    }

    // Добавление новой компании
    function addCompany(string memory name, address addr, uint256 rate, uint256 points) external onlyOwner {
        // Добавление новую компанию в mapping
        companies[name] = Company(
            name,
            addr,
            rate,
            points
        );

        // Добавляем название в массив всех компаний
        listOFCompanies.push(name);
        // Оповещаем блокчейн о том, что в систему BULP добавлена новая компания
        emit AddCompany(name, addr, rate, points);
    }

    // Компания может посмотреть список клиентов своей программы лояльности
    function getClientsList() external view returns (address[] memory) {
        return mappingCompanyClients[_msgSender()];
    }

    // Можно посмотреть список всех компаний
    function showCompanies() external view returns (string[] memory) {
        return listOFCompanies;
    }

}
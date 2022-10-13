// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;

interface IRussPass {

    // Структура данных для хранения компаний
    struct Company{
        string name;
        address addr;
        uint256 rate;
        uint256 points;
    }

    // Структура данных для хранения клиентов
    struct Client{
        address addr;
        uint256 tokensBuyed;
    }

    //Клиент купил на токены
    event BuyRussPassTokens(string loyaltyName, uint256 pointsCount, uint256 rate, uint256 tokenCount);

    //Клиент обменял токены на баллы
    event SellRussPassTokens(string loyaltyName, uint256 tokenCount, uint256 rate, uint256 pointsCount);
    
    //Клиент купил баллы
    event BuyPoints(string loyaltyName, uint256 pointsCount, uint256 rate);

    //Клиент обменял баллы на токены
    event SellPoints(string loyaltyName, uint256 pointsCount, uint256 rate);

    //Добавлена новая компания
    event AddCompany(string name, address addr, uint256 rate, uint256 points);

    //Добавлен новый клиент
    event AddClient(address addr);

    //Добавлен новый клиент
    event AddLoyaltyProgram(string loyaltyName, address addr);

    // Функция для генерации новых токенов
    function generateNewTokens(uint256 _numTokens) external;

    // Баланс токенов контракта 
    function balanceOf() external view returns (uint256);

    // Баланс токенов клиента
    function clientTokens() external view returns (uint256);

    //Пркупка токенов
    function buyTokens(string memory loyaltyName, uint256 tokenCount) external;

    //Продажа токенов
    function sellTokens(string memory loyaltyName, uint256 pointsCount) external;

    // Добавляение нового клиента
    function addClient(address addr, uint256 tokensBuyed) external;

    // Клиент может подключить программу лояльности
    function addLoyaltyProgram(string memory loyaltyName, uint256 pointsCount) external;

    // Клиент может посмотретьть свой список программ лояльности
    function showClientLoyaltyCards() external view returns (string[] memory);

    //Добавление новой компании
    function addCompany(string memory name, address addr, uint256 rate, uint256 points) external;

    // Компания может посмотреть список клиентов своей программы лояльности
    function getClientsList() external view returns (address[] memory);

    // Посмотреть список всех компаний
    function showCompanies() external view returns (string[] memory);

}
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

function getEnvVar(key) {
    const value = process.env[key];
    if (!value) {
        throw new Error(`Missing environment variable: ${key}`);
    }
    return value;
}

const employees = [
    {
        address: getEnvVar("EMPLOYEE_ONE__ADDRESS"),
        name: "employee1",
    },
    {
        address: getEnvVar("EMPLOYEE_TWO_ADDRESS"),
        name: "employee2",
    },
];

const config = {
    directorPrivateKey: getEnvVar("DIRECTOR_PRIVATE_KEY"),
    verifyingContract: getEnvVar("CLONE_ADDRESS"),
    employees,
};

module.exports = config;

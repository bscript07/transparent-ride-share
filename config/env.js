const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

function getEnvVar(key) {
    const value = process.env[key];
    if (!value) {
        throw new Error(`Missing environment variable: ${key}`);
    }
    return value;
}

const drivers = [
    {
        address: getEnvVar("DRIVER_ONE__ADDRESS"),
        name: "driver1",
    },
    {
        address: getEnvVar("DRIVER_TWO__ADDRESS"),
        name: "driver2",
    },
];

const config = {
    ownerPrivateKey: getEnvVar("OWNER_PRIVATE_KEY"),
    verifyingContract: getEnvVar("CLONE_ADDRESS"),
    drivers,
};

module.exports = config;

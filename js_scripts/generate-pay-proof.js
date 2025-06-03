const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");
const { directorPrivateKey, employees, verifyingContract } = require("../config/env");

async function generatePayProof() {
    const wallet = new ethers.Wallet(directorPrivateKey);

    const domain = {
        name: "Paysalary",
        version: "1",
        chainId: 11155111,
        verifyingContract
    };

    const types = {
        PayProof: [
            { name: "employee", type: "address" },
            { name: "period", type: "uint256" },
            { name: "usdAmount", type: "uint256" },
        ],
    };

    const period = 202405;
    const usdAmount = 1250;

    const allSignatures = [];

    for (const emp of employees) {
        const message = {
            employee: emp.address,
            period,
            usdAmount,
        };

        const signature = await wallet.signTypedData(domain, types, message);

        const data = {
            ...message,
            domain,
            signature,
            name: emp.name,
        };

        allSignatures.push(data);
    }

    const filePath = path.join(__dirname, "signature.json");
    fs.writeFileSync(filePath, JSON.stringify(allSignatures));

    console.log(`✅ All pay-proofs signed and saved to ${filePath}`);
}

generatePayProof().catch((err) => {
    console.error("Error: ", err);
});


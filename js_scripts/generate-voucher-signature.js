const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");
const { ownerPrivateKey, drivers, verifyingContract } = require("../config/env");

async function generateTripVouchers() {
    const wallet = new ethers.Wallet(ownerPrivateKey);

    const domain = {
        name: "Vouchers",
        version: "1",
        chainId: 11155111,
        verifyingContract
    };

    const types = {
        TripVoucher: [
            { name: "driver", type: "address" },
            { name: "tripId", type: "uint256"},
            { name: "usdCents", type: "uint256" },
            { name: "expiry", type: "uint256" },
        ],
    };

    const tripId = 1;
    const usdCents = 500; // $5.00 in cents
    const expiry = Math.floor(Date.now() / 1000) + 3600; // expires in 1 hour

    const allSignatures = [];

    for (const operator of drivers) {
        const message = {
            driver: operator.address,
            tripId,
            usdCents,
            expiry,
        };

        const signature = await wallet.signTypedData(domain, types, message);

        const data = {
            ...message,
            domain,
            signature,
            name: operator.name,
        };

        allSignatures.push(data);
    }

    const filePath = path.join(__dirname, "signature.json");
    fs.writeFileSync(filePath, JSON.stringify(allSignatures, null, 2));

    console.log(`✅ All vouchers signed and saved to ${filePath}`);
}

generateTripVouchers().catch((err) => {
    console.error("Error: ", err);
});


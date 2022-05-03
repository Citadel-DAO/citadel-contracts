contracts=$(find src  -maxdepth 1 -type f -exec basename {} \;| sed -r 's/.sol//';)
rm -rf abis/*
rm -rf contracts/*
for i in $contracts
do
    echo $i
    forge inspect $i abi > abis/$i.json
done
mkdir contracts
typechain --target=ethers-v5 --out-dir contracts/ abis/*
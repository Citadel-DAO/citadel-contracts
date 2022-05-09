const path = require("path");
const fs = require("fs");

const storeConfigs = (basePath, filename, config) => {
  if (!fs.existsSync(basePath)) {
    fs.mkdirSync(basePath);
  }
  if (fs.existsSync(path.join(basePath, `${filename}.json`))) {
    fs.unlinkSync(path.join(basePath, `${filename}.json`));
  }
  fs.writeFileSync(
    path.join(basePath, `${filename}.json`),
    JSON.stringify(config),
    (err) => {
      if (err) {
        console.error(err);
        return;
      }
    }
  );
};

module.exports = storeConfigs;

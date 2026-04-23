const { execSync } = require("node:child_process");
const { existsSync } = require("node:fs");
const { join } = require("node:path");

function resolveTableFormatRule() {
  const home = process.env.HOME || "";
  const miseRule = join(
    home,
    ".local/share/mise/installs/npm-markdownlint-rule-table-format/latest/lib/node_modules/markdownlint-rule-table-format/rule.js"
  );
  if (existsSync(miseRule)) {
    return miseRule;
  }

  try {
    return require.resolve("markdownlint-rule-table-format/rule.js");
  } catch {}

  try {
    const npmRoot = execSync("npm root -g", { encoding: "utf8" }).trim();
    const candidate = join(npmRoot, "markdownlint-rule-table-format/rule.js");
    if (existsSync(candidate)) {
      return candidate;
    }
  } catch {}

  return null;
}

const tableFormatRule = resolveTableFormatRule();

module.exports = {
  customRules: tableFormatRule ? [tableFormatRule] : [],
  config: {
    MD060: {
      style: "compact",
    },
    ...(tableFormatRule
      ? {
          "table-format": {
            style: "compact",
            aligned_delimiter: false,
          },
        }
      : {}),
  },
};

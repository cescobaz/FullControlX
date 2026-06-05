const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = plugin(function({matchComponents, theme}) {
  let baseDir = path.join(__dirname, "../../deps/remixicons/icons");
  let values = {};
  let icons = fs
    .readdirSync(baseDir, { withFileTypes: true })
    .filter((dirent) => dirent.isDirectory())
    .map((dirent) => dirent.name);

  icons.forEach((dir) => {
    fs.readdirSync(path.join(baseDir, dir)).map((file) => {
      let name = path.basename(file, ".svg");
      values[name] = { name, fullPath: path.join(baseDir, dir, file) };
    });
  });

  matchComponents(
    {
      ri: ({ name, fullPath }) => {
        let content = fs
          .readFileSync(fullPath)
          .toString()
          .replace(/\r?\n|\r/g, "");

        return {
          [`--ri-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "-webkit-mask": `var(--ri-${name})`,
          mask: `var(--ri-${name})`,
          "background-color": "currentColor",
          "vertical-align": "middle",
          display: "inline-block",
          width: theme("spacing.10"),
          height: theme("spacing.10"),
        };
      },
    },
    { values },
  );
})

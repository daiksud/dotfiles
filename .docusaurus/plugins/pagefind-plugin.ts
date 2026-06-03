import type { Plugin } from "@docusaurus/types";
import { join } from "node:path";
import { readdir, readFile } from "node:fs/promises";

async function findHtmlFiles(dir: string): Promise<string[]> {
  const entries = await readdir(dir, { withFileTypes: true, recursive: true });
  return entries
    .filter((e) => e.isFile() && e.name.endsWith(".html"))
    .map((e) => join(e.parentPath ?? e.path, e.name));
}

export default function pagefindPlugin(): Plugin {
  return {
    name: "docusaurus-plugin-pagefind",
    async postBuild({ outDir, siteDir }) {
      const pagefind = await import(
        join(siteDir, "node_modules", "pagefind", "lib", "index.js")
      );
      const { index } = await pagefind.createIndex();

      const htmlFiles = await findHtmlFiles(outDir);
      for (const file of htmlFiles) {
        const relative = file.slice(outDir.length);
        // /path.html -> /path, but keep /index.html as /
        const url =
          relative === "/index.html"
            ? "/"
            : relative.replace(/\/index\.html$/, "/").replace(/\.html$/, "");
        const content = await readFile(file, "utf-8");
        await index.addHTMLFile({ url, content });
      }

      await index.writeFiles({ outputPath: join(outDir, "pagefind") });
      const count = htmlFiles.length;
      console.log(`[Pagefind] Indexed ${count} pages to build/pagefind`);
      await pagefind.close();
    },
  };
}

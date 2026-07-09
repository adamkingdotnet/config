import js from "@eslint/js";
import globals from "globals";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";
import tseslint from "typescript-eslint";
import eslintConfigPrettier from "eslint-config-prettier";
import { defineConfig, globalIgnores } from "eslint/config";

// Shared Vite + React flat config for the dashboard repos (finances, health).
// Consumer eslint.config.js collapses to:
//   import viteReact from "@king/config/eslint/vite-react";
//   export default viteReact();                                        // finances
//   export default viteReact({ strict: true, tsconfigRootDir: import.meta.dirname }); // health
//
// `strict: true` reproduces health's type-aware setup (strictTypeChecked +
// stylisticTypeChecked, projectService parser, prettier-last, the three rule
// relaxations, and no-magic-numbers off in tests). Default reproduces finances.
// The no-magic-numbers component rule (warn on hardcoded values in .tsx) is
// shared; `strict` adds 60 to the ignore list. Override via `magicNumberIgnores`.
export default function viteReact({ strict = false, tsconfigRootDir, magicNumberIgnores } = {}) {
  const ignore =
    magicNumberIgnores ??
    (strict
      ? [-1, 0, 1, 2, 3, 4, 5, 6, 10, 12, 24, 60, 100, 1000]
      : [-1, 0, 1, 2, 3, 4, 5, 6, 10, 12, 24, 100, 1000]);

  const mainBlock = {
    files: ["**/*.{ts,tsx}"],
    extends: strict
      ? [
          js.configs.recommended,
          tseslint.configs.strictTypeChecked,
          tseslint.configs.stylisticTypeChecked,
          reactHooks.configs.flat["recommended-latest"],
          reactRefresh.configs.vite,
          eslintConfigPrettier,
        ]
      : [
          js.configs.recommended,
          tseslint.configs.recommended,
          reactHooks.configs.flat.recommended,
          reactRefresh.configs.vite,
        ],
    languageOptions: {
      globals: globals.browser,
      ...(strict ? { parserOptions: { projectService: true, tsconfigRootDir } } : {}),
    },
    ...(strict
      ? {
          rules: {
            "@typescript-eslint/no-non-null-assertion": "off",
            "@typescript-eslint/restrict-template-expressions": ["error", { allowNumber: true }],
            "@typescript-eslint/no-confusing-void-expression": ["error", { ignoreArrowShorthand: true }],
          },
        }
      : {}),
  };

  return defineConfig([
    globalIgnores(["dist"]),
    mainBlock,
    {
      files: ["src/tabs/**/*.tsx", "src/components/**/*.tsx", "src/charts/**/*.tsx"],
      rules: {
        "no-magic-numbers": [
          "warn",
          {
            ignore,
            ignoreArrayIndexes: true,
            ignoreDefaultValues: true,
            ignoreClassFieldInitialValues: true,
            enforceConst: false,
            detectObjects: false,
          },
        ],
      },
    },
    ...(strict ? [{ files: ["**/*.test.{ts,tsx}"], rules: { "no-magic-numbers": "off" } }] : []),
  ]);
}

import js from "@eslint/js";
import tseslint from "typescript-eslint";
import globals from "globals";

// Shared flat config for the Cloudflare Worker repos (mls, pulse).
// Consumer eslint.config.mjs collapses to:
//   import worker from "@king/config/eslint/worker";
//   export default worker;
export default [
  {
    ignores: [
      "**/node_modules/**",
      "**/dist/**",
      "**/.wrangler/**",
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["**/*.ts"],
    languageOptions: {
      globals: {
        ...globals.serviceworker,
        ...globals.node,
      },
    },
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
        },
      ],
    },
  },
];
